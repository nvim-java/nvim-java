local class = require('java-core.utils.class')

local M = class()

---@return vim.lsp.Client
local function get_client()
	local clients = vim.lsp.get_clients({ name = 'jdtls' })

	if #clients < 1 then
		local message = string.format('No jdtls client found to instantiate class')
		require('java-core.utils.notify').error(message)
		require('java.utils.log').error(message)
		error(message)
	end

	return clients[1]
end

---@return java-core.JdtlsClient
function M.jdtls_client()
	return require('java-core.ls.clients.jdtls-client')(get_client())
end

return M
