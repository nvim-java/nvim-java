local get_error_handler = require('java.handlers.error')

---Returns an active jdtls client
---@return vim.lsp.Client
local function get_jdtls()
	local clients

	if vim.lsp.get_clients then
		clients = vim.lsp.get_clients({ name = 'jdtls' })
	else
		clients = vim.lsp.get_active_clients({ name = 'jdtls' })
	end

	if #clients == 0 then
		get_error_handler('could not find an active jdtls client')()
	end

	return clients[1]
end

return get_jdtls
