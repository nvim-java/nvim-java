local M = {}

function M.get_curr_buf()
	return vim.api.nvim_get_current_buf()
end

function M.get_curr_uri()
	local buffer = M.get_curr_buf()

	return vim.uri_from_bufnr(buffer)
end

return M
