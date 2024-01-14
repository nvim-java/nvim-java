local spy = require('luassert.spy')
local mock = require('luassert.mock')
local notify = require('java-core.utils.notify')
local DapSetup = require('java-dap.api.setup')
local mock_client = { jdtls_args = {} }
local runner = require('java.api.runner')

local RunnerApi = runner.RunnerApi:new({ client = mock_client })

describe('java-core.api.runner', function()
	it('RunnerApi:new', function()
		local mock_dap = DapSetup(mock_client)
		assert.same(RunnerApi.client, mock_client)
		assert.same(RunnerApi.dap, mock_dap)
	end)

	it('RunnerApi:get_config when no config found', function()
		local dap_mock = mock(DapSetup, true)
		dap_mock.get_dap_config.returns({})

		local notify_spy = spy.on(notify, 'warn')
		local config = RunnerApi:get_config()

		assert.equals(config, nil)
		assert.spy(notify_spy).was_called_with('Dap config not found')
		mock.revert()
	end)

	it('RunnerApi:get_config when only one config found', function()
		local dap_mock = mock(DapSetup, true)
		dap_mock.get_dap_config.returns({
			{ name = 'config1', projectName = 'projectName' },
		})

		local config = RunnerApi:get_config()
		assert.same(config, { name = 'config1', projectName = 'projectName' })
		mock.revert()
	end)

	it('RunnerApi:get_config when multiple config found', function()
		RunnerApi.dap.get_dap_config = function()
			return {
				{ name = 'config1' },
				{ name = 'config2', projectName = 'project2' },

				{ name = 'config3', projectName = 'project3' },
			}
		end

		local ui = mock(vim.ui, true)
		local mock_select = function(main_class_choices, opts, callback)
			assert.same(main_class_choices, { 'config2', 'config3' })
			assert.same(opts, {
				prompt = 'Select the main class (modul -> mainClass)',
			})
			callback('config2', 2)
		end

		ui.select = mock_select
		local config = RunnerApi:get_config()

		assert.same({ name = 'config2', projectName = 'project2' }, config)
		mock.revert(ui)
	end)

	it('RunnerApi:run_app when no config found', function()
		RunnerApi.get_config = function()
			return nil
		end

		local callback_mock = function(_) end
		local callback_spy = spy.new(callback_mock)

		RunnerApi:run_app(callback_spy)
		assert.spy(callback_spy).was_not_called()
	end)

	it('RUnnerApi:run_app without args', function()
		RunnerApi.get_config = function()
			return { name = 'config1' }
		end

		RunnerApi.dap.enrich_config = function()
			return {
				classPaths = { 'path1', 'path2' },
				mainClass = 'mainClass',
				javaExec = 'javaExec',
			}
		end

		local callback_mock = function(_, _) end
		local callback_spy = spy.new(callback_mock)

		RunnerApi:run_app(callback_spy)
		assert.spy(callback_spy).was_called_with({
			'javaExec',
			'',
			'-cp',
			'path1:path2',
			'mainClass',
		})
	end)

	it('RUnnerApi:run_app with args', function()
		RunnerApi.get_config = function()
			return { name = 'config1' }
		end

		RunnerApi.dap.enrich_config = function()
			return {
				classPaths = { 'path1', 'path2' },
				mainClass = 'mainClass',
				javaExec = 'javaExec',
			}
		end

		local callback_mock = function(_, _) end
		local callback_spy = spy.new(callback_mock)

		RunnerApi:run_app(callback_spy, 'args')
		assert.spy(callback_spy).was_called_with({
			'javaExec',
			'args',
			'-cp',
			'path1:path2',
			'mainClass',
		})
	end)

	it('BuildInRunner:new', function()
		local built_in_main_runner = runner.BuiltInMainRunner:new()
		assert.equals(built_in_main_runner.is_open, false)
	end)

	it('BuildInRunner:_set_up_buffer', function()
		local vim = mock(vim, true)
		local spy_cmd = spy.on(vim, 'cmd')

		local api = mock(vim.api, true)
		api.nvim_get_current_win.returns(1)

		local spy_nvim_win_set_option = spy.on(api, 'nvim_win_set_option')

		local built_in_main_runner = runner.BuiltInMainRunner:new()
		built_in_main_runner.bufnr = 1
		built_in_main_runner.is_open = true
		spy.on(built_in_main_runner, '_set_up_buffer_autocmd')
		built_in_main_runner:_set_up_buffer()

		assert.equals(built_in_main_runner.is_open, false)
		assert.spy(spy_cmd).was_called_with('sp | winc J | res 15 | buffer 1')

		assert.spy(spy_nvim_win_set_option).was_called_with(1, 'number', false)
		assert
			.spy(spy_nvim_win_set_option)
			.was_called_with(1, 'relativenumber', false)
		assert.spy(spy_nvim_win_set_option).was_called_with(1, 'signcolumn', 'no')
		assert.spy(built_in_main_runner._set_up_buffer_autocmd).was_called()

		mock.revert(vim)
		mock.revert(api)
	end)

	it('BuildInRunner:_set_up_buffer_autocmd', function()
		local api = mock(vim.api, true)

		local built_in_main_runner = runner.BuiltInMainRunner:new()
		built_in_main_runner.bufnr = 1
		built_in_main_runner.is_open = false
		built_in_main_runner:_set_up_buffer_autocmd()

		local call_info = api.nvim_create_autocmd.calls[1]
		assert.same(call_info.vals[1], { 'BufHidden' })
		assert.equals(call_info.vals[2].buffer, 1)

		call_info.vals[2].callback()
		assert.is_true(built_in_main_runner.is_open)

		mock.revert(api)
	end)

	it(
		'BuiltInMainRunner:_on_stdout when bufnr is equal to current bufnr and mode is "i" (skip scroll)',
		function()
			local mock_current_bufnr = 1
			local vim = mock(vim, true)
			local api = mock(vim.api, true)
			local spy_chensend = spy.on(vim.fn, 'chansend')

			api.nvim_get_current_buf.returns(mock_current_bufnr)
			api.nvim_get_mode.returns({ mode = 'i' })

			local built_in_main_runner = runner.BuiltInMainRunner:new()
			built_in_main_runner.chan = 2
			built_in_main_runner.bufnr = mock_current_bufnr
			spy.on(built_in_main_runner, '_scroll_down')

			built_in_main_runner:_on_stdout({ 'data1', 'data2' })

			assert.spy(spy_chensend).was_called_with(2, { 'data1', 'data2' })
			-- call nvim_create_buf
			local call_info = api.nvim_buf_call.calls[1]
			call_info.vals[2]()
			assert.spy(built_in_main_runner._scroll_down).was_not_called()
			--
			mock.revert(vim)
			mock.revert(api)
		end
	)

	it(
		'BuiltInMainRunner:_on_stdout when bufnr is not equal to current bufnr and mode is "i" (scroll)',
		function()
			local api = mock(vim.api, true)
			local spy_chensend = spy.on(vim.fn, 'chansend')

			api.nvim_get_current_buf.returns(2)
			api.nvim_get_mode.returns({ mode = 'i' })

			local built_in_main_runner = runner.BuiltInMainRunner:new()
			built_in_main_runner.bufnr = 1
			built_in_main_runner.chan = 2
			spy.on(built_in_main_runner, '_scroll_down')
			built_in_main_runner:_on_stdout({ 'data1', 'data2', 'data3' })

			assert.spy(spy_chensend).was_called_with(2, { 'data1', 'data2', 'data3' })
			local call_info = api.nvim_buf_call.calls[1]
			assert.equals(call_info.vals[1], 1)

			call_info.vals[2]()
			assert.spy(built_in_main_runner._scroll_down).was_called()

			mock.revert(api)
		end
	)

	it(
		'BuiltInMainRunner:_on_stdout when bufnr is equal to current bufnr and mode is not "i" (scroll)',
		function()
			local mock_current_bufnr = 1
			local api = mock(vim.api, true)
			local spy_chensend = spy.on(vim.fn, 'chansend')

			api.nvim_get_current_buf.returns(mock_current_bufnr)
			api.nvim_get_mode.returns({ mode = 'n' })
			api.nvim_buf_line_count.returns(3)

			local built_in_main_runner = runner.BuiltInMainRunner:new()
			built_in_main_runner.bufnr = mock_current_bufnr
			built_in_main_runner.chan = 2
			spy.on(built_in_main_runner, '_scroll_down')
			built_in_main_runner:_on_stdout({ 'data1', 'data2' })

			assert.spy(spy_chensend).was_called_with(2, { 'data1', 'data2' })
			local call_info = api.nvim_buf_call.calls[1]
			assert.equals(call_info.vals[1], 1)

			call_info.vals[2]()
			assert.spy(built_in_main_runner._scroll_down).was_called()

			mock.revert(api)
		end
	)

	it(
		'BuiltInMainRunner:_on_exit when bufnr is equal to current bufnr (scroll)',
		function()
			local mock_current_bufnr = 1
			local api = mock(vim.api, true)
			local spy_chensend = spy.on(vim.fn, 'chansend')
			local spy_cmd = spy.on(vim, 'cmd')

			api.nvim_get_current_buf.returns(mock_current_bufnr)

			local built_in_main_runner = runner.BuiltInMainRunner:new()
			built_in_main_runner.bufnr = mock_current_bufnr
			built_in_main_runner.chan = 2
			built_in_main_runner:_on_exit(0)

			assert
				.spy(spy_chensend)
				.was_called_with(2, '\nProcess finished with exit code 0\n')
			assert.spy(spy_cmd).was_called_with('stopinsert')
			assert.equals(built_in_main_runner.job_id, nil)

			mock.revert(api)
		end
	)

	it(
		'BuiltInMainRunner:_on_exit when bufnr is not equal to current bufnr (skip scroll)',
		function()
			local mock_current_bufnr = 1
			local api = mock(vim.api, true)
			local spy_chensend = spy.on(vim.fn, 'chansend')
			local spy_cmd = spy.on(vim, 'cmd')

			api.nvim_get_current_buf.returns(mock_current_bufnr)

			local built_in_main_runner = runner.BuiltInMainRunner:new()
			built_in_main_runner.bufnr = mock_current_bufnr + 1
			built_in_main_runner.chan = 2
			built_in_main_runner:_on_exit(0)

			assert
				.spy(spy_chensend)
				.was_called_with(2, '\nProcess finished with exit code 0\n')
			assert.spy(spy_cmd).was_not_called()
			assert.equals(built_in_main_runner.job_id, nil)

			mock.revert(api)
		end
	)

	it('BuiltInMainRunner:run_app when there is no running job', function()
		local fn = mock(vim.fn, true)
		local spy_jobstart = spy.on(fn, 'jobstart')
		local spy_chansend = spy.on(fn, 'chansend')
		local spy_stop = spy.on(fn, 'jobstop')
		local api = mock(vim.api, true)

		api.nvim_create_buf.returns(1)
		api.nvim_open_term.returns(2)

		local built_in_main_runner = runner.BuiltInMainRunner:new()
		built_in_main_runner:run_app({ 'java', '-cp', 'path1:path2', 'mainClass' })

		assert
			.spy(spy_chansend)
			.was_called_with(2, 'java -cp path1:path2 mainClass')
		assert.stub(api.nvim_buf_call).was_called()
		assert.spy(spy_jobstart).was_called()
		assert.not_nil(built_in_main_runner.job_id)

		local call_info = fn.jobstart.calls[1]
		assert.equals(call_info.vals[1], 'java -cp path1:path2 mainClass')
		assert.not_nil(call_info.vals[2].on_exit)
		assert.not_nil(call_info.vals[2].on_stdout)
		assert.spy(spy_stop).was_not_called()

		mock.revert(api)
		mock.revert(fn)
	end)

	it('BuiltInMainRunner:run_app when there is a running job', function()
		local fn = mock(vim.fn, true)
		local spy_chensend = spy.on(fn, 'chansend')
		local spy_jobstart = spy.on(fn, 'jobstart')
		local spy_jobwait = spy.on(fn, 'jobwait')
		local spy_stop = spy.on(fn, 'jobstop')
		local api = mock(vim.api, true)

		api.nvim_create_buf.returns(1)
		api.nvim_open_term.returns(2)

		local built_in_main_runner = runner.BuiltInMainRunner:new()
		built_in_main_runner.bufnr = 11
		built_in_main_runner.job_id = 1
		built_in_main_runner:run_app({ 'java', '-cp', 'path1:path2', 'mainClass' })

		assert
			.spy(spy_chensend)
			.was_called_with(2, 'java -cp path1:path2 mainClass')
		assert.spy(spy_stop).was_called_with(1)
		assert.spy(spy_jobstart).was_called()
		assert.spy(spy_jobwait).was_called_with({ 1 }, 1000)

		mock.revert(api)
		mock.revert(fn)
	end)

	it('BuiltInMainRunner:toggle_logs when is_open=true', function()
		local api = mock(vim.api, true)

		api.nvim_buf_line_count.returns(3)

		local built_in_main_runner = runner.BuiltInMainRunner:new()
		built_in_main_runner.is_open = true
		built_in_main_runner.bufnr = 11
		spy.on(built_in_main_runner, '_set_up_buffer')
		spy.on(built_in_main_runner, 'hide_logs')

		built_in_main_runner:toggle_logs()

		local call_info = api.nvim_buf_call.calls[1]
		assert.equals(call_info.vals[1], 11)

		call_info.vals[2]()
		assert.spy(built_in_main_runner._set_up_buffer).was_called()
		assert.spy(built_in_main_runner.hide_logs).was_not_called()

		mock.revert(api)
	end)

	it('BuiltInMainRunner:toggle_logs when is_open=false', function()
		local api = mock(vim.api, true)

		local built_in_main_runner = runner.BuiltInMainRunner:new()
		built_in_main_runner.is_open = false
		spy.on(built_in_main_runner, 'hide_logs')

		built_in_main_runner:toggle_logs()

		assert.stub(api.nvim_buf_call).was_not_called()
		assert.spy(built_in_main_runner.hide_logs).was_called()

		mock.revert(api)
	end)

	it('BuiltInMainRunner:stop when job_id is nil', function()
		local fn = mock(vim.fn, true)
		local spy_jobstop = spy.on(fn, 'jobstop')

		local built_in_main_runner = runner.BuiltInMainRunner:new()
		built_in_main_runner:stop()

		assert.spy(spy_jobstop).was_not_called()

		mock.revert(fn)
	end)

	it('BuiltInMainRunner:hide_logs', function()
		local vim = mock(vim, true)
		local spy_cmd = spy.on(vim, 'cmd')
		local api = mock(vim.api, true)

		local built_in_main_runner = runner.BuiltInMainRunner:new()
		built_in_main_runner.bufnr = 1
		built_in_main_runner:hide_logs()

		local call_info = api.nvim_buf_call.calls[1]
		assert.equals(call_info.vals[1], 1)
		assert.is_function(call_info.vals[2])

		call_info.vals[2]()
		assert.spy(spy_cmd).was_called_with('hide')

		mock.revert(vim)
		mock.revert(api)
	end)

	it('built_in.run_app', function()
		local built_in_main_runner_mock = mock(runner.BuiltInMainRunner, true)
		built_in_main_runner_mock.new.returns(built_in_main_runner_mock)
		spy.on(built_in_main_runner_mock, 'run_app')
		spy.on(built_in_main_runner_mock, 'new')

		runner.run_app = function(callback, args)
			assert.equals(args, 'args')
			callback()
		end

		runner.built_in.run_app({ args = 'args' })

		assert.not_nil(runner.BuiltInMainRunner)
		assert.spy(built_in_main_runner_mock.new).was_called()
		assert.spy(built_in_main_runner_mock.run_app).was_called()
	end)

	it('built_in.toggle_logs', function()
		local built_in_main_runner_mock = mock(runner.BuiltInMainRunner, true)
		spy.on(built_in_main_runner_mock, 'toggle_logs')
		runner.BuildInRunner = built_in_main_runner_mock

		runner.built_in.toggle_logs()
		assert.spy(built_in_main_runner_mock.toggle_logs).was_called()

		runner.BuildInRunner = nil
	end)

	it('built_in.stop_app', function()
		local built_in_main_runner_mock = mock(runner.BuiltInMainRunner, true)
		spy.on(built_in_main_runner_mock, 'stop')

		runner.BuildInRunner = built_in_main_runner_mock

		runner.built_in.stop_app()
		assert.spy(built_in_main_runner_mock.stop).was_called()
		runner.BuildInRunner = nil
	end)
end)
