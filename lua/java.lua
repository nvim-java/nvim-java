local decomple_watch = require('java.startup.decompile-watcher')
local mason_dep = require('java.startup.mason-dep')
local setup_wrap = require('java.startup.lspconfig-setup-wrap')

local test = require('java.api.test')
local dap = require('java.api.dap')
local runner = require('java.api.runner')
local profile_ui = require('java.ui.profile')
local refactor = require('java.api.refactor')
local log = require('java.utils.log')
local notify = require('java-core.utils.notify')

local global_config = require('java.config')

local M = {
	checks = {
		require('java.startup.exec-order-check'),
		require('java.startup.duplicate-setup-check'),
		require('java.startup.nvim-dep'),
	},
}

function M.setup(custom_config)
	local config =
		vim.tbl_deep_extend('force', global_config, custom_config or {})

	vim.g.nvim_java_config = config

	for _, check in ipairs(M.checks) do
		local check_res = check.is_valid()

		if check_res.message then
			if not check_res.success then
				log.error(check_res.message)
				notify.error(check_res.message)
			else
				log.warn(check_res.message)
				notify.warn(check_res.message)
			end
		end

		if not check_res.continue then
			return
		end
	end

	local is_installing = mason_dep.install(config)

	if not is_installing then
		setup_wrap.setup(config)
		decomple_watch.setup()
		dap.setup_dap_on_lsp_attach()
	end
end

----------------------------------------------------------------------
--                             DAP APIs                             --
----------------------------------------------------------------------
M.dap = {}
M.dap.config_dap = dap.config_dap

----------------------------------------------------------------------
--                            Test APIs                             --
----------------------------------------------------------------------
M.test = {}
M.test.run_current_class = test.run_current_class
M.test.debug_current_class = test.debug_current_class

M.test.run_current_method = test.run_current_method
M.test.debug_current_method = test.debug_current_method

M.test.view_last_report = test.view_last_report

----------------------------------------------------------------------
--                            Manipulate                            --
----------------------------------------------------------------------

M.manipulate = {}
-- M.manipulate.organize_imports = {}

----------------------------------------------------------------------
--                             Refactor                             --
----------------------------------------------------------------------
M.refactor = {}
M.refactor.extract_variable = refactor.extract_variable

----------------------------------------------------------------------
--                            Runner APIs                           --
----------------------------------------------------------------------
M.runner = {}
M.runner.built_in = {}
M.runner.built_in.run_app = runner.built_in.run_app
M.runner.built_in.toggle_logs = runner.built_in.toggle_logs
M.runner.built_in.stop_app = runner.built_in.stop_app
M.runner.built_in.switch_app = runner.built_in.switch_app

----------------------------------------------------------------------
--                             Profile UI                           --
----------------------------------------------------------------------
M.profile = {}
M.profile.ui = profile_ui.ui

function M.__run()
	test.debug_current_method()
end

return M
