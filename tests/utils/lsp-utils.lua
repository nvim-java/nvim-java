local M = {}

---Wait for LSP client to attach
---@param name string LSP client name
---@param timeout? number Timeout in milliseconds (defaults to 30000)
---@return vim.lsp.Client client The attached LSP client
function M.wait_for_lsp_attach(name, timeout)
	timeout = timeout or 30000

	local is_attached = function()
		local clients = vim.lsp.get_clients({ name = name })
		return #clients > 0
	end

	local success = vim.wait(timeout, is_attached, 100)

	if not success then
		error(string.format('LSP client "%s" failed to attach within %dms', name, timeout))
	end

	local clients = vim.lsp.get_clients({ name = name })
	return clients[1]
end

return M
