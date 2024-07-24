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

return M
