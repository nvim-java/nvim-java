local runner_api = require('java.api.runner')
local settings_api = require('java.api.settings')
local profile_ui = require('java.ui.profile')

local M = {}

---@param custom_config java.PartialConfig | nil
function M.setup(custom_config)
	local default_conf = require('java.config')
	local test_api = require('java-test')

	local config = vim.tbl_deep_extend('force', default_conf, custom_config or {})

	vim.g.nvim_java_config = config

	----------------------------------------------------------------------
	--                       neovim version check                       --
	----------------------------------------------------------------------
	if config.checks.nvim_version then
		if vim.fn.has('nvim-0.11.5') ~= 1 then
			local err = require('java-core.utils.errors')
			err.throw([[
					nvim-java is only tested on Neovim 0.11.5 or greater
					Please upgrade to Neovim 0.11.5 or greater.
					If you are sure it works on your version, disable the version check:
					 checks = { nvim_version = false }'
				]])
		end
	end

	----------------------------------------------------------------------
	--                          logger setup                            --
	----------------------------------------------------------------------
	if config.log then
		require('java-core.utils.log2').setup(config.log --[[@as java-core.PartialLog2Config]])
	end

	----------------------------------------------------------------------
	--                       package installation                       --
	----------------------------------------------------------------------
	local Manager = require('pkgm.manager')
	local pkgm = Manager()

	pkgm:install('jdtls', config.jdtls.version)

	if config.java_test.enable then
		----------------------------------------------------------------------
		--                               test                               --
		----------------------------------------------------------------------
		pkgm:install('java-test', config.java_test.version)

		M.test = {
			run_current_class = test_api.run_current_class,
			debug_current_class = test_api.debug_current_class,

			run_current_method = test_api.run_current_method,
			debug_current_method = test_api.debug_current_method,

			view_last_report = test_api.view_last_report,
		}
	end

	if config.java_debug_adapter.enable then
		----------------------------------------------------------------------
		--                             debugger                             --
		----------------------------------------------------------------------
		pkgm:install('java-debug', config.java_debug_adapter.version)
		require('java-dap').setup()

		M.dap = {
			config_dap = function()
				require('java-dap').config_dap()
			end,
		}
	end

	if config.spring_boot_tools.enable then
		pkgm:install('spring-boot-tools', config.spring_boot_tools.version)
	end

	if config.lombok.enable then
		pkgm:install('lombok', config.lombok.version)
	end

	if config.jdk.auto_install then
		pkgm:install('openjdk', config.jdk.version)
	end

	----------------------------------------------------------------------
	--                               init                               --
	----------------------------------------------------------------------
	require('java.startup.lsp_setup').setup(config)
	require('java.startup.decompile-watcher').setup()
	require('java-refactor').setup()
end

----------------------------------------------------------------------
--                            Runner APIs                           --
----------------------------------------------------------------------
M.runner = {}
M.runner.built_in = {}
M.runner.built_in.run_app = runner_api.built_in.run_app
M.runner.built_in.toggle_logs = runner_api.built_in.toggle_logs
M.runner.built_in.stop_app = runner_api.built_in.stop_app
M.runner.built_in.switch_app = runner_api.built_in.switch_app

----------------------------------------------------------------------
--                             Profile UI                           --
----------------------------------------------------------------------
M.profile = {}
M.profile.ui = profile_ui.ui

----------------------------------------------------------------------
--                             Settings                             --
----------------------------------------------------------------------
M.settings = {}
M.settings.change_runtime = settings_api.change_runtime

return M
