require('java.commands')

local decomple_watch = require('java.startup.decompile-watcher')
local mason_dep = require('java.startup.mason-dep')
local setup_wrap = require('java.startup.lspconfig-setup-wrap')
local startup_check = require('java.startup.startup-check')

local test = require('java.api.test')
local dap = require('java.api.dap')
local runner = require('java.api.runner')
local profile_ui = require('java.ui.profile')
local refactor = require('java.api.refactor')
local build_api = require('java.api.build')
local settings_api = require('java.api.settings')

local global_config = require('java.config')

local M = {}

function M.setup(custom_config)
	vim.api.nvim_exec_autocmds('User', { pattern = 'JavaPreSetup' })

	local config =
		vim.tbl_deep_extend('force', global_config, custom_config or {})

	vim.g.nvim_java_config = config

	vim.api.nvim_exec_autocmds(
		'User',
		{ pattern = 'JavaSetup', data = { config = config } }
	)

	if not startup_check() then
		return
	end

	local is_installing = mason_dep.install(config)

	if not is_installing then
		setup_wrap.setup(config)
		decomple_watch.setup()
		dap.setup_dap_on_lsp_attach()
	end

	vim.api.nvim_exec_autocmds(
		'User',
		{ pattern = 'JavaPostSetup', data = { config = config } }
	)
end

----------------------------------------------------------------------
--                        Experimental APIs                         --
----------------------------------------------------------------------
M.build = {}
M.build.build_workspace = build_api.full_build_workspace

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
M.refactor.extract_constant = refactor.extract_constant
M.refactor.extract_method = refactor.extract_method
M.refactor.extract_field = refactor.extract_field
M.refactor.convert_variable_to_field = refactor.convert_variable_to_field
M.refactor.extract_variable_all_occurrence =
	refactor.extract_variable_all_occurrence

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

----------------------------------------------------------------------
--                             Settings                             --
----------------------------------------------------------------------
M.settings = {}
M.settings.change_runtime = settings_api.change_runtime

function M.__run()
	test.debug_current_method()
end

return M
