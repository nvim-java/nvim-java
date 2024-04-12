local JavaDap = require('java.dap')

local log = require('java.utils.log')
local get_error_handler = require('java.handlers.error')
local jdtls = require('java.utils.jdtls')
local async = require('java-core.utils.async').sync
local notify = require('java-core.utils.notify')
local project_config = require('java.api.profile_config')

local M = {}

---Setup dap config & adapter on jdtls attach event
function M.setup_dap_on_lsp_attach()
	log.info('add LspAttach event handlers to setup dap adapter & config')

	M.even_id = vim.api.nvim_create_autocmd('LspAttach', {
		callback = M.on_jdtls_attach,
		group = vim.api.nvim_create_augroup('nvim-java-dap-config', {}),
	})
end

function M.config_dap()
	log.info('configuring dap')

	return async(function()
			local config = vim.g.nvim_java_config
			if config.notifications.dap then
				notify.warn('Configuring DAP')
			end
			JavaDap:new(jdtls()):config_dap()
			if config.notifications.dap then
				notify.info('DAP configured')
			end
		end)
		.catch(get_error_handler('dap configuration failed'))
		.run()
end

function M.on_jdtls_attach(ev)
	local client = vim.lsp.get_client_by_id(ev.data.client_id)

	if client == nil then
		return
	end

	local server_name = client.name

	if server_name == 'jdtls' then
		log.info('setup java dap config & adapter')

		project_config.setup()
		M.config_dap()
		-- removing the event handler after configuring dap
		vim.api.nvim_del_autocmd(M.even_id)
	end
end

return M
