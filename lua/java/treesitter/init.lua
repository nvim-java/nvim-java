local queries = require('java.treesitter.queries')

local M = {}

---Finds a main method in the given buffer and returns the line number
---@return integer | nil line number of the main method
function M.find_main_method(buffer)
	local query = vim.treesitter.query.parse('java', queries.main_class)
	local parser = vim.treesitter.get_parser(buffer, 'java')
	local root = parser:parse()[1]:root()

	for _, match, _ in query:iter_matches(root, buffer, 0, -1) do
		for id, node in pairs(match) do
			local capture_name = query.captures[id]

			if capture_name == 'main_method' then
				-- first element is the line number
				return ({ node:start() })[1]
			end
		end
	end

	return nil
end

return M
