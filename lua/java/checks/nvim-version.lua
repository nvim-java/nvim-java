local M = {}

---Run nvim version check
---@param config java.Config
function M:run(config)
	if not config.checks.nvim_version then
		return
	end

	if vim.fn.has('nvim-0.11') ~= 1 then
		local err = require('java-core.utils.errors')
		err.throw([[
				nvim-java is only tested on Neovim 0.11 or greater
				Please upgrade to Neovim 0.11 or greater.
				If you are sure it works on your version, disable the version check:
				 checks = { nvim_version = false }'
			]])
	end
end

return M
