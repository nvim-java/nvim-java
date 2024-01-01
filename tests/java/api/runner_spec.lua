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

	it('RUnnerApi:run_app when no config found', function()
		RunnerApi.get_config = function()
			return nil
		end

		local callback_mock = function(_) end
		local callback_spy = spy.new(callback_mock)

		RunnerApi:run_app(callback_spy)
		assert.spy(callback_spy).was_not_called()
	end)

	it('RUnnerApi:run_app', function()
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

		local callback_mock = function(_) end
		local callback_spy = spy.new(callback_mock)

		RunnerApi:run_app(callback_spy)
		assert.spy(callback_spy).was_called_with({
			'javaExec',
			'-cp',
			'path1:path2',
			'mainClass',
		})
	end)
end)
