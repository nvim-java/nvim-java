local deps = require('java.utils.dependencies')
local mason = require('java.utils.mason')
local lspconfig = require('java.utils.lspconfig')

local dap = require('java.dap.api')
local ts = require('java.treesitter')

local M = {}

function M.setup()
	deps.check()
	mason.install_dependencies()
	lspconfig.wrap_lspconfig_setup()
	lspconfig.register_class_file_decomplier()
	dap.setup_dap_on_lsp_attach()
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
M.test.run_current_test_class = dap.run_current_test_class
M.test.debug_current_test_class = dap.debug_current_test_class

----------------------------------------------------------------------
--                            Manipulate                            --
----------------------------------------------------------------------
M.manipulate = {}
-- M.manipulate.organize_imports = {}

function M.__run()
	ts.find_main_method()
end

return M
