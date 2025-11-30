local M = {
	opts = {},
}

local function index(this, level)
	return function(msg, opts)
		vim.notify(msg, vim.log.levels[level:upper()], vim.tbl_deep_extend('force', this.opts or {}, opts or {}))
	end
end

setmetatable(M, {
	__index = index,
	__call = function(_, opts)
		return setmetatable({ opts = opts or {} }, {
			__index = index,
		})
	end,
})

return M({
	title = 'Java',
})
