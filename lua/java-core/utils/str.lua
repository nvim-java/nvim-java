local M = {}

--- Joins a list of strings with a separator
---@param ... string
---@return string
function M.multiline(...)
	return table.concat({ ... }, '\n')
end

return M
