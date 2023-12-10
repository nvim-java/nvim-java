local decomple_watch = require('java.startup.decompile-watcher')
local mason_dep = require('java.startup.mason-dep')
local nvim_dep = require('java.startup.nvim-dep')
local setup_wrap = require('java.startup.lspconfig-setup-wrap')

local test = require('java.api.test')
local dap = require('java.api.dap')
local settings = require('java.api.settings')

local global_config = require('java.config')

local M = {}

function M.setup(custom_config)
	local config =
		vim.tbl_deep_extend('force', global_config, custom_config or {})

	nvim_dep.check()

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
--                             Settings                             --
----------------------------------------------------------------------
M.settings = {}
M.settings.change_runtime = settings.change_runtime

----------------------------------------------------------------------
--                            Manipulate                            --
----------------------------------------------------------------------
M.manipulate = {}
-- M.manipulate.organize_imports = {}

function M.__run()
	require('java.api.settings').change_runtime()
end

return M
