local get_error_handler = require('java.handlers.error')

---Returns an active jdtls client
---@return { client: LspClient }
local function get_jdtls()
	local clients = vim.lsp.get_clients({ name = 'jdtls' })

	if #clients == 0 then
		get_error_handler('could not find an active jdtls client')()
	end

	return {
		client = clients[1],
	}
end

return get_jdtls
