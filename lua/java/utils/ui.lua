local async = require('java-core.utils.async')
local await = async.wait

local M = {}

function M.select(prompt, values)
	return await(function(callback)
		vim.ui.select(values, {
			prompt = prompt,
		}, callback)
	end)
end

return M
