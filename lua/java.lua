local deps = require('java.dependencies')
local java_mason = require('java.mason')
local java_dap = require('java.dap')
local java_lspconfig = require('java.lspconfig')
local ts = require('java.treesitter')

local M = {}

function M.setup()
	deps.check()
	java_lspconfig.wrap_lspconfig_setup()
	java_mason.install_dependencies()
	java_dap.setup_dap()
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

----------------------------------------------------------------------
--                            Manipulate                            --
----------------------------------------------------------------------
M.manipulate = {}
-- M.manipulate.organize_imports = {}

function M.__run()
	ts.find_main_method()
end

return M
