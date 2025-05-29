local decomple_watch = require('java.startup.decompile-watcher')
local mason_dep = require('java.startup.mason-dep')
local setup_wrap = require('java.startup.lspconfig-setup-wrap')
local startup_check = require('java.startup.startup-check')

local command_util = require('java.utils.command')

local test_api = require('java.api.test')
local dap_api = require('java.api.dap')
local runner_api = require('java.api.runner')
local settings_api = require('java.api.settings')
local profile_ui = require('java.ui.profile')

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

	if is_installing then
		return
	end

	setup_wrap.setup(config)
	decomple_watch.setup()
	if config.java_debug_adapter.enable then
		dap_api.setup_dap_on_lsp_attach()
	end

	vim.api.nvim_exec_autocmds(
		'User',
		{ pattern = 'JavaPostSetup', data = { config = config } }
	)
end

---@param path string[]
---@param command fun()
---@param opts vim.api.keyset.user_command
function M.register_api(path, command, opts)
	local name = command_util.path_to_command_name(path)

	vim.api.nvim_create_user_command(name, command, opts or {})

	local last_index = #path
	local func_name = path[last_index]

	table.remove(path, last_index)

	local node = M

	for _, v in ipairs(path) do
		if not node[v] then
			node[v] = {}
		end

		node = node[v]
	end

	node[func_name] = command
end

----------------------------------------------------------------------
--                             DAP APIs                             --
----------------------------------------------------------------------
M.dap = {}
M.dap.config_dap = dap_api.config_dap

----------------------------------------------------------------------
--                            Test APIs                             --
----------------------------------------------------------------------
M.test = {}
M.test.run_current_class = test_api.run_current_class
M.test.debug_current_class = test_api.debug_current_class

M.test.run_current_method = test_api.run_current_method
M.test.debug_current_method = test_api.debug_current_method

M.test.view_last_report = test_api.view_last_report

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
