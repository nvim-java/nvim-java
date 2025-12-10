local M = {}

---Run nvim version check
---@param config java.Config
function M:run(config)
	if not config.checks.nvim_version then
		return
	end

	if not vim.version.ge(vim.version(), '0.11.5') then
		local err = require('java-core.utils.errors')
		err.throw([[
				nvim-java is only tested on Neovim 0.11.5 or greater
				Please upgrade to Neovim 0.11.5 or greater.
			]])
	end
end

return M
