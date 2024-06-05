local spy = require('luassert.spy')
local mock = require('luassert.mock')
local notify = require('java-core.utils.notify')
local DapSetup = require('java-dap.api.setup')
local mock_client = { jdtls_args = {} }
local runner = require('java.api.runner')
local async = require('java-core.utils.async').sync
local profile_config = require('java.api.profile_config')
local ui = require('java.utils.ui')

local RunnerApi = runner.RunnerApi({ client = mock_client })

describe('java-core.api.runner', function()
	before_each(function()
		package.loaded['java.api.runner'] = nil
		package.loaded['java.utils.ui'] = nil
	end)

	it('RunnerApi()', function()
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
		assert.spy(notify_spy).was_called_with('Config not found')
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

		local mock_ui = mock(vim.ui, true)
		mock_ui.select.returns()

		local select_spy = spy.on(vim.ui, 'select')

		async(function()
			local config = RunnerApi:get_config()
			assert.same({ name = 'config2', projectName = 'project2' }, config)
			mock.revert(mock_ui)
		end).run()

		assert.same(select_spy.calls[1].vals[1], { 'config2', 'config3' })

		assert.same(
			select_spy.calls[1].vals[2],
			{ prompt = 'Select the main class (modul -> mainClass)' }
		)

		mock.revert(mock_ui)
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

	it('RunnerApi:run_app without active profile', function()
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

		RunnerApi.profile_config = profile_config
		RunnerApi.profile_config.get_active_profile = function(main_class)
			assert.equals(main_class, 'mainClass')
			return nil
		end

		local callback_mock = function(_, _) end
		local callback_spy = spy.new(callback_mock)

		RunnerApi:run_app(callback_spy)
		assert.spy(callback_spy).was_called_with({
			'javaExec',
			'', -- vm_args
			'-cp',
			'path1:path2',
			'mainClass',
			'', -- prog_args
		}, { name = 'config1', request = 'launch' })
	end)

	it('RunnerApi:run_app with active profile', function()
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

		RunnerApi.profile_config = profile_config
		RunnerApi.profile_config.get_active_profile = function(main_class)
			assert.equals(main_class, 'mainClass')
			return {
				prog_args = 'profile_prog_args',
				vm_args = 'vm_args',
			}
		end

		local callback_mock = function(_, _) end
		local callback_spy = spy.new(callback_mock)

		RunnerApi:run_app(callback_spy, 'input_prog_args')
		assert.spy(callback_spy).was_called_with({
			'javaExec',
			'vm_args',
			'-cp',
			'path1:path2',
			'mainClass',
			'profile_prog_args input_prog_args',
		}, { name = 'config1', request = 'launch' })
	end)

	it('RunningApp:new', function()
		local api = mock(vim.api, true)
		api.nvim_create_buf.returns(1)
		local running_app = runner.RunningApp({ projectName = 'projectName' })
		assert.equals(running_app.win, nil)
		assert.equals(running_app.bufnr, 1)
		assert.equals(running_app.job_id, nil)
		assert.equals(running_app.chan, nil)
		assert.same(running_app.dap_config, { projectName = 'projectName' })
		assert.equals(running_app.is_open, false)
		assert.equals(running_app.running_status, nil)
		mock.revert(api)
	end)

	it('BuildInRunner:new', function()
		local built_in_main_runner = runner.BuiltInMainRunner()
		assert.equals(built_in_main_runner.current_app, nil)
		assert.same(built_in_main_runner.running_apps, {})
	end)

	it('BuildInRunner:_set_up_buffer', function()
		local vim = mock(vim, true)
		vim.wo = {}
		vim.wo[1] = {}
		local api = mock(vim.api, true)
		api.nvim_get_current_win.returns(1)
		api.nvim_create_buf.returns(2)
		local spy_cmd = spy.on(vim, 'cmd')

		local running_app = runner.RunningApp({ projectName = 'projectName' })

		spy.on(runner.BuiltInMainRunner, 'set_up_buffer_autocmd')
		runner.BuiltInMainRunner.set_up_buffer(running_app)

		assert.equals(running_app.is_open, true)
		assert.equals(running_app.win, 1)
		assert.spy(spy_cmd).was_called_with('sp | winc J | res 15 | buffer 2')
		assert.spy(runner.BuiltInMainRunner.set_up_buffer_autocmd).was_called()

		mock.revert(api)
		mock.revert(vim)
	end)

	it('BuildInRunner:_set_up_buffer_autocmd', function()
		local api = mock(vim.api, true)
		api.nvim_create_buf.returns(1)

		local running_app = runner.RunningApp({ projectName = 'projectName' })
		running_app.is_open = true
		runner.BuiltInMainRunner.set_up_buffer_autocmd(running_app)

		local call_info = api.nvim_create_autocmd.calls[1]
		assert.same(call_info.vals[1], { 'BufHidden' })
		assert.equals(call_info.vals[2].buffer, 1)

		call_info.vals[2].callback()
		assert.is_false(running_app.is_open)

		mock.revert(api)
	end)

	it('BuiltInMainRunner.on_stdout when is_open=true', function()
		local api = mock(vim.api, true)
		local spy_chensend = spy.on(vim.fn, 'chansend')

		local running_app = runner.RunningApp({ projectName = 'projectName' })
		running_app.chan = 2

		spy.on(vim.api, 'nvim_buf_call')
		runner.BuiltInMainRunner.on_stdout({ 'data1', 'data2' }, running_app)
		assert.spy(spy_chensend).was_called_with(2, { 'data1', 'data2' })

		assert.spy(api.nvim_buf_call).was_not_called()

		mock.revert(api)
	end)

	it(
		'BuiltInMainRunner.on_stdout when bufnr is equal to current bufnr and mode is "i" (skip scroll)',
		function()
			local mock_current_bufnr = 1
			local vim = mock(vim, true)
			local api = mock(vim.api, true)
			local spy_chensend = spy.on(vim.fn, 'chansend')

			api.nvim_get_current_buf.returns(mock_current_bufnr)
			api.nvim_create_buf.returns(mock_current_bufnr)
			api.nvim_get_mode.returns({ mode = 'i' })

			local running_app = runner.RunningApp({ projectName = 'projectName' })
			running_app.chan = 2
			running_app.is_open = true
			-- running_app.bufnr = mock_current_bufnr
			spy.on(runner.BuiltInMainRunner, 'scroll_down')

			runner.BuiltInMainRunner.on_stdout({ 'data1', 'data2' }, running_app)

			assert.spy(spy_chensend).was_called_with(2, { 'data1', 'data2' })
			-- -- call nvim_create_buf
			local call_info = api.nvim_buf_call.calls[1]
			call_info.vals[2]()

			assert.spy(runner.BuiltInMainRunner.scroll_down).was_not_called()
			--
			mock.revert(vim)
			mock.revert(api)
		end
	)

	it(
		'BuiltInMainRunner:_on_stdout when bufnr is not equal to current bufnr and mode is "i" (scroll)',
		function()
			local vim = mock(vim, true)
			local api = mock(vim.api, true)
			local spy_chensend = spy.on(vim.fn, 'chansend')

			api.nvim_get_current_buf.returns(1)
			api.nvim_create_buf.returns(3)
			api.nvim_get_mode.returns({ mode = 'i' })

			local running_app = runner.RunningApp({ projectName = 'projectName' })
			running_app.chan = 2
			running_app.is_open = true
			-- running_app.bufnr = mock_current_bufnr
			spy.on(runner.BuiltInMainRunner, 'scroll_down')

			runner.BuiltInMainRunner.on_stdout({ 'data1', 'data2' }, running_app)

			assert.spy(spy_chensend).was_called_with(2, { 'data1', 'data2' })
			-- -- call nvim_create_buf
			local call_info = api.nvim_buf_call.calls[1]
			call_info.vals[2]()

			assert
				.spy(runner.BuiltInMainRunner.scroll_down)
				.was_called_with(running_app)
			--
			mock.revert(vim)
			mock.revert(api)
		end
	)

	it(
		'BuiltInMainRunner:_on_stdout when bufnr is equal to current bufnr and mode is not "i" (scroll)',
		function()
			local vim = mock(vim, true)
			local api = mock(vim.api, true)
			local spy_chensend = spy.on(vim.fn, 'chansend')

			api.nvim_get_current_buf.returns(1)
			api.nvim_create_buf.returns(1)
			api.nvim_get_mode.returns({ mode = 'n' })

			local running_app = runner.RunningApp({ projectName = 'projectName' })
			running_app.chan = 2
			running_app.is_open = true
			-- running_app.bufnr = mock_current_bufnr
			spy.on(runner.BuiltInMainRunner, 'scroll_down')

			runner.BuiltInMainRunner.on_stdout({ 'data1', 'data2' }, running_app)

			assert.spy(spy_chensend).was_called_with(2, { 'data1', 'data2' })
			-- -- call nvim_create_buf
			local call_info = api.nvim_buf_call.calls[1]
			call_info.vals[2]()

			assert
				.spy(runner.BuiltInMainRunner.scroll_down)
				.was_called_with(running_app)
			--
			mock.revert(vim)
			mock.revert(api)
		end
	)

	it(
		'BuiltInMainRunner:_on_exit when bufnr is equal to current bufnr (stopinsert)',
		function()
			local mock_current_bufnr = 1
			local api = mock(vim.api, true)
			local spy_chensend = spy.on(vim.fn, 'chansend')
			local spy_cmd = spy.on(vim, 'cmd')

			api.nvim_get_current_buf.returns(mock_current_bufnr)
			api.nvim_create_buf.returns(mock_current_bufnr)

			local running_app =
				runner.RunningApp({ projectName = 'projectName', name = 'config1' })
			running_app.chan = 2
			running_app.is_open = true
			running_app.job_id = 1

			runner.BuiltInMainRunner.on_exit(0, running_app)
			assert
				.spy(spy_chensend)
				.was_called_with(2, '\nProcess finished with exit code 0\n')
			assert.spy(spy_cmd).was_called_with('stopinsert')
			assert.equals(
				running_app.running_status,
				'Process finished with exit code 0'
			)

			mock.revert(api)
		end
	)

	it(
		'BuiltInMainRunner:_on_exit when bufnr is not equal to current bufnr (skip stopinsert)',
		function()
			local api = mock(vim.api, true)
			local spy_chensend = spy.on(vim.fn, 'chansend')
			local spy_cmd = spy.on(vim, 'cmd')

			api.nvim_get_current_buf.returns(3)
			api.nvim_create_buf.returns(4)

			local running_app =
				runner.RunningApp({ projectName = 'projectName', name = 'config1' })
			running_app.chan = 2
			running_app.is_open = true
			running_app.job_id = 1

			runner.BuiltInMainRunner.on_exit(0, running_app)
			assert
				.spy(spy_chensend)
				.was_called_with(2, '\nProcess finished with exit code 0\n')
			assert.spy(spy_cmd).was_not_called()
			assert.equals(
				running_app.running_status,
				'Process finished with exit code 0'
			)

			mock.revert(api)
		end
	)

	it('BuiltInMainRunner:run_app when there is no running job', function()
		local fn = mock(vim.fn, true)
		local spy_jobstart = spy.on(fn, 'jobstart')
		local spy_chansend = spy.on(fn, 'chansend')
		local api = mock(vim.api, true)

		api.nvim_create_buf.returns(1)
		api.nvim_open_term.returns(2)

		local running_app = runner.RunningApp()
		running_app.is_open = false
		running_app.dap_config = { name = 'config1' }

		local built_in_main_runner = runner.BuiltInMainRunner()

		runner.BuiltInMainRunner.set_up_buffer = function(selected_app)
			assert.equals(selected_app, running_app)
		end
		runner.BuiltInMainRunner.scroll_down = function(selected_app)
			assert.equals(selected_app, running_app)
		end

		local spy_stop = spy.on(runner.BuiltInMainRunner, 'stop')

		built_in_main_runner.select_app_with_dap_config = function()
			return running_app
		end

		built_in_main_runner:run_app(
			{ 'java', '-cp', 'path1:path2', 'mainClass' },
			{ name = 'config1' }
		)

		assert.equals(running_app.chan, 2)
		assert.equals(running_app.running_status, '(running)')

		assert
			.spy(spy_chansend)
			.was_called_with(2, 'java -cp path1:path2 mainClass')
		assert.stub(api.nvim_buf_call).was_called()
		assert.spy(spy_jobstart).was_called()

		local call_info = fn.jobstart.calls[1]
		assert.equals(call_info.vals[1], 'java -cp path1:path2 mainClass')
		assert.not_nil(call_info.vals[2].on_exit)
		assert.not_nil(call_info.vals[2].on_stdout)
		assert.spy(spy_stop).was_not_called()
		assert.spy(api.nvim_buf_set_name).was_called_with(1, 'config1')

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

		local running_app = runner.RunningApp()
		running_app.is_open = false
		running_app.job_id = 1
		running_app.dap_config = { name = 'config1' }

		local built_in_main_runner = runner.BuiltInMainRunner()
		built_in_main_runner.current_app = running_app

		runner.BuiltInMainRunner.set_up_buffer = function(selected_app)
			assert.equals(selected_app, running_app)
		end
		runner.BuiltInMainRunner.scroll_down = function(selected_app)
			assert.equals(selected_app, running_app)
		end
		runner.BuiltInMainRunner.change_current_app = function(app)
			assert.equals(app.job_id, nil) -- check if job_id is nil
		end

		built_in_main_runner.select_app_with_dap_config = function()
			return running_app
		end

		built_in_main_runner:run_app(
			{ 'java', '-cp', 'path1:path2', 'mainClass' },
			{ name = 'config1' }
		)

		assert.equals(running_app.running_status, '(running)')
		assert.is_nil(running_app.job_id)
		assert
			.spy(spy_chensend)
			.was_called_with(2, 'java -cp path1:path2 mainClass')
		assert.spy(spy_stop).was_called_with(1)
		assert.spy(spy_jobstart).was_called()
		assert.spy(spy_jobwait).was_called_with({ 1 }, 1000)
		assert.spy(api.nvim_buf_set_name).was_called_with(1, 'config1')

		mock.revert(api)
		mock.revert(fn)
	end)

	it('BuiltInMainRunner:toggle_logs when is_open=true', function()
		local api = mock(vim.api, true)
		api.nvim_create_buf.returns(11)

		local running_app = runner.RunningApp()
		running_app.is_open = true

		runner.BuiltInMainRunner.hide_logs = function(selected_app)
			assert.equals(selected_app, running_app)
		end

		local spy_set_up_buffer = spy.on(runner.BuiltInMainRunner, 'set_up_buffer')
		local spy_hide_logs = spy.on(runner.BuiltInMainRunner, 'hide_logs')

		runner.BuiltInMainRunner.toggle_logs(running_app)

		assert.spy(spy_hide_logs).was_called()
		assert.spy(spy_set_up_buffer).was_not_called()

		mock.revert(api)
	end)

	it('BuiltInMainRunner:toggle_logs when is_open=false', function()
		local api = mock(vim.api, true)
		api.nvim_create_buf.returns(1)

		local running_app = runner.RunningApp()
		running_app.is_open = false

		runner.BuiltInMainRunner.set_up_buffer = function(selected_app)
			assert.equals(selected_app, running_app)
		end

		runner.BuiltInMainRunner.scroll_down = function(selected_app)
			assert.equals(selected_app, running_app)
		end

		local spy_set_up_buffer = spy.on(runner.BuiltInMainRunner, 'set_up_buffer')
		local spy_hide_logs = spy.on(runner.BuiltInMainRunner, 'hide_logs')

		runner.BuiltInMainRunner.toggle_logs(running_app)

		local call_info = api.nvim_buf_call.calls[1]
		assert.equals(call_info.vals[1], 1)
		call_info.vals[2]()

		assert.spy(spy_hide_logs).was_not_called()
		assert.spy(spy_set_up_buffer).was_called()

		mock.revert(api)
	end)

	it('BuiltInMainRunner:stop when job_id is nil', function()
		local running_app = runner.RunningApp()
		running_app.job_id = nil

		local fn_job_stop_spy = spy.on(vim.fn, 'jobstop')
		local fn_job_wait_spy = spy.on(vim.fn, 'jobwait')
		runner.BuiltInMainRunner.stop(running_app)

		assert.spy(fn_job_stop_spy).was_not_called()
		assert.spy(fn_job_wait_spy).was_not_called()
	end)

	it('BuiltInMainRunner:stop when job_id is not nil', function()
		local running_app = runner.RunningApp()
		running_app.job_id = 1

		local fn_job_stop_spy = spy.on(vim.fn, 'jobstop')
		local fn_job_wait_spy = spy.on(vim.fn, 'jobwait')

		runner.BuiltInMainRunner.stop(running_app)

		assert.spy(fn_job_stop_spy).was_called_with(1)
		assert.spy(fn_job_wait_spy).was_called_with({ 1 }, 1000)
	end)

	it(
		'BuiltInMainRunner:select_from_avaible_apps when no running apps',
		function()
			local build_in_main_runner = runner.BuiltInMainRunner()
			build_in_main_runner.running_apps = {}

			assert.error(function()
				build_in_main_runner:select_app_with_ui()
			end)
		end
	)

	it(
		'BuildInRunner:select_from_running_apps when only one running app',
		function()
			local build_in_main_runner = runner.BuiltInMainRunner()
			local running_app = runner.RunningApp({ projectName = 'projectName' })
			build_in_main_runner.running_apps = { running_app }

			local selected_app = build_in_main_runner:select_app_with_ui()
			assert.equals(selected_app, running_app)
		end
	)

	it(
		'BuildInRunner:select_from_running_apps when multiple running apps',
		function()
			local running_app1 = runner.RunningApp({
				projectName = 'projectName1',
				mainClass = 'mainClass1',
			})
			local running_app2 = runner.RunningApp({
				projectName = 'projectName2',
				mainClass = 'mainClass2',
			})

			local build_in_main_runner = runner.BuiltInMainRunner()
			build_in_main_runner.running_apps[running_app1.dap_config.mainClass] =
				running_app1
			build_in_main_runner.running_apps[running_app2.dap_config.mainClass] =
				running_app2

			build_in_main_runner.change_current_app = function(_) end

			local spy_change_current_app =
				spy.on(build_in_main_runner, 'change_current_app')

			ui.select_from_dap_configs = function(configs)
				assert(#configs == 2)
				return running_app2.dap_config
			end

			local result = build_in_main_runner:select_app_with_ui()
			assert.equals(result, running_app2)

			assert.spy(spy_change_current_app).was_called()
		end
	)

	it('BuildInRunner:select_app_with_dap_config when no config', function()
		local build_in_main_runner = runner.BuiltInMainRunner()
		assert.error(function()
			build_in_main_runner:select_app_with_dap_config()
		end)
	end)

	it(
		'BuildInRunner:select_app_with_dap_config when config is not found',
		function()
			local build_in_main_runner = runner.BuiltInMainRunner()
			build_in_main_runner.running_apps = {}

			local config = { projectName = 'projectName', mainClass = 'mainClass' }
			local selected_app =
				build_in_main_runner:select_app_with_dap_config(config)

			assert.equals(selected_app.dap_config, config)
		end
	)

	it('BuildInRunner:select_app_with_dap_config when config is found', function()
		local build_in_main_runner = runner.BuiltInMainRunner()
		build_in_main_runner.running_apps = {}

		local config1 = { projectName = 'projectName1', mainClass = 'mainClass1' }
		local config2 = { projectName = 'projectName2', mainClass = 'mainClass2' }

		build_in_main_runner.running_apps[config1.mainClass] =
			runner.RunningApp(config1)
		build_in_main_runner.running_apps[config2.mainClass] =
			runner.RunningApp(config2)

		local selected_app =
			build_in_main_runner:select_app_with_dap_config(config2)
		assert.equals(selected_app.dap_config, config2)
	end)

	it('BuildInRunner:change_current_app', function()
		local build_in_main_runner = runner.BuiltInMainRunner()
		local running_app1 = runner.RunningApp({ projectName = 'projectName1' })
		local running_app2 = runner.RunningApp({ projectName = 'projectName2' })

		runner.BuiltInMainRunner.hide_logs = function(selected_app)
			assert.equals(selected_app, running_app2)
		end

		local spy_hide_logs = spy.on(runner.BuiltInMainRunner, 'hide_logs')

		build_in_main_runner.current_app = running_app1

		build_in_main_runner.hide_logs = function(selected_app)
			assert.equals(selected_app, running_app1)
		end

		assert.spy(spy_hide_logs).was_not_called()
		build_in_main_runner.current_app = running_app2
		build_in_main_runner:change_current_app(running_app1)
	end)

	it('BuildInRunner:change_current_app when dap config is equal', function()
		local build_in_main_runner = runner.BuiltInMainRunner()
		local running_app1 = runner.RunningApp({ projectName = 'projectName1' })

		local spy_hide_logs = spy.on(runner.BuiltInMainRunner, 'hide_logs')

		build_in_main_runner.current_app = running_app1

		build_in_main_runner.hide_logs = function(selected_app)
			assert.equals(selected_app, running_app1)
		end

		build_in_main_runner:change_current_app(running_app1)

		assert.spy(spy_hide_logs).was_not_called()
		build_in_main_runner.current_app = running_app1
	end)
end)
