local deps = require('java.dependencies')
local java_mason = require('java.mason')
local java_dap = require('java.dap')
local java_lspconfig = require('java.lspconfig')
local ts = require('java.treesitter')

local M = {}

function M.setup()
	deps.check()
	java_mason.install_dependencies()
	java_lspconfig.wrap_lspconfig_setup()
	java_lspconfig.register_class_file_decomplier()
	java_dap.setup_dap_on_lsp_attach()
end

----------------------------------------------------------------------
--                             DAP APIs                             --
----------------------------------------------------------------------
M.dap = {}
M.dap.config_dap = java_dap.config_dap

----------------------------------------------------------------------
--                            Test APIs                             --
----------------------------------------------------------------------
M.test = {}
M.test.run_current_test_class = java_dap.run_current_test_class
M.test.debug_current_test_class = java_dap.debug_current_test_class
M.test.hello = java_dap.debug_current_test_class

----------------------------------------------------------------------
--                            Manipulate                            --
----------------------------------------------------------------------
M.manipulate = {}
-- M.manipulate.organize_imports = {}

function M.__run()
	ts.find_main_method()
end

return M
