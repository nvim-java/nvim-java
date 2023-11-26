local deps = require('java.utils.dependencies')
local mason = require('java.utils.mason')
local lspconfig = require('java.utils.lspconfig')

local test = require('java.api.test')
local dap = require('java.api.dap')
-- local ts = require('java.treesitter')

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
M.test.run_current_test_class = test.run_current_test_class
M.test.debug_current_test_class = test.debug_current_test_class

----------------------------------------------------------------------
--                            Manipulate                            --
----------------------------------------------------------------------
M.manipulate = {}
-- M.manipulate.organize_imports = {}

function M.__run()
	test.debug_current_method()
end

return M
