local StringBuilder = function()
	local str = ''

	local M = {}
	M.append = function(text, prefix)
		prefix = prefix or ''
		if type(text) == 'table' then
			for _, line in ipairs(text) do
				str = str .. prefix .. line .. '\n'
			end
		else
			assert(type(text) == 'string')
			str = str .. prefix .. text
		end
		return M
	end

	M.lbreak = function()
		str = str .. '\n'
		return M
	end

	M.build = function()
		return str
	end

	return M
end

return StringBuilder
