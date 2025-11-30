local M = {}

---Converts a path array to command name
---@param path string[]
---@return string
function M.path_to_command_name(path)
	local name = 'Java'

	for _, word in ipairs(path) do
		local sub_words = vim.split(word, '_')
		local changed_word = ''

		for _, sub_word in ipairs(sub_words) do
			local first_char = sub_word:sub(1, 1):upper()
			local rest = sub_word:sub(2)
			changed_word = changed_word .. first_char .. rest
		end

		name = name .. changed_word
	end

	return name
end

---Registers an API by creating a user command and adding to module table
---@param module table
---@param path string[]
---@param command fun()
---@param opts vim.api.keyset.user_command
function M.register_api(module, path, command, opts)
	local name = M.path_to_command_name(path)

	vim.api.nvim_create_user_command(name, command, opts or {})

	local last_index = #path
	local func_name = path[last_index]

	table.remove(path, last_index)

	local node = module

	for _, v in ipairs(path) do
		if not node[v] then
			node[v] = {}
		end

		node = node[v]
	end

	node[func_name] = command
end

return M
