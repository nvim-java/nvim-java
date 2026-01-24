local M = {}

if vim.fn.has('win32') == 1 or vim.fn.has('win32unix') == 1 then
	M.path_separator = '\\'
	M.classpath_seperator = ';'
else
	M.path_separator = '/'
	M.classpath_seperator = ':'
end

---Join a given list of paths to one path
---@param ... string paths to join
---@return string # joined path
function M.join(...)
	return table.concat({ ... }, M.path_separator)
end

return M
