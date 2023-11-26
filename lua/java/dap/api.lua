local JavaDap = require('java.dap')

local log = require('java.utils.log')
local get_error_handler = require('java.handlers.error')
local jdtls = require('java.utils.jdtls')
local async = require('java-core.utils.async').sync

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

function M.run_current_test_class()
	log.info('run current test class')

	return async(function()
			return JavaDap:new(jdtls()):execute_current_test_class({ noDebug = true })
		end)
		.catch(get_error_handler('failed to run the current test class'))
		.run()
end

function M.debug_current_test_class()
	log.info('debug current test class')

	return async(function()
			return JavaDap:new(jdtls()):execute_current_test_class({})
		end)
		.catch(get_error_handler('failed to debug the current test class'))
		.run()
end

function M.config_dap()
	log.info('configuring dap')

	return async(function()
			JavaDap:new(jdtls()):config_dap()
		end)
		.catch(get_error_handler('dap configuration failed'))
		.run()
end

function M.on_jdtls_attach(ev)
	local client = vim.lsp.get_client_by_id(ev.data.client_id)

	if client.name == 'jdtls' then
		log.info('setup java dap config & adapter')

		M.config_dap()
	end
end

return M
