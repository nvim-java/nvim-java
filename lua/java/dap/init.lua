local JavaDap = require('java.dap.dapp')

local log = require('java-core.utils.log')
local state = require('java.state')
local notify = require('java-core.utils.notify')

local M = {}

---Setup dap config & adapter on jdtls attach event
function M.setup_dap()
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
	state.java_dap:run_current_test_class()
end

---Configures the dap
function M.config_dap()
	state.java_dap:config_dap():thenCall(function()
		notify.info('DAP configured')
	end)
end

---@private
---@param ev any
function M.on_jdtls_attach(ev)
	local client = vim.lsp.get_client_by_id(ev.data.client_id)

	if client.name == 'jdtls' then
		state.java_dap = JavaDap:new({
			client = client,
		})

		log.info('setup java dap config & adapter')

		state.java_dap:config_dap()
	end
end

return M
