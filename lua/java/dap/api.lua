local JavaDap = require('java.dap')

local log = require('java.utils.log')
local notify = require('java-core.utils.notify')
local get_error_handler = require('java.handlers.error')
local jdtls = require('java.jdtls')

local M = {}

---Setup dap config & adapter on jdtls attach event
function M.setup_dap_on_lsp_attach()
	log.info('add LspAttach event handlers to setup dap adapter & config')

	vim.api.nvim_create_autocmd('LspAttach', {
		pattern = '*',
		callback = M.on_jdtls_attach,
		once = true,
		group = vim.api.nvim_create_augroup('nvim-java-dap-config', {}),
	})
end

---Runs the current test class
function M.run_current_test_class()
	return JavaDap:new(jdtls()):execute_current_test_class({ noDebug = true })
end

function M.debug_current_test_class()
	return JavaDap:new(jdtls()):execute_current_test_class({})
end

---Configures the dap
function M.config_dap()
	return JavaDap:new(jdtls())
		:config_dap()
		:catch(get_error_handler('failed to configure dap'))
end

---@private
---@param ev any
function M.on_jdtls_attach(ev)
	local client = vim.lsp.get_client_by_id(ev.data.client_id)

	if client.name == 'jdtls' then
		log.info('setup java dap config & adapter')

		M.config_dap()
	end
end

return M
