local M = {}

function M.get_cursor()
	local cursor = vim.api.nvim_win_get_cursor(0)

	return {
		-- apparently the index is not 0 based
		line = cursor[1] - 1,
		column = cursor[2],
	}
end

return M
