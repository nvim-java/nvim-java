local M = {}

---Check if nvim-jdtls plugin is installed
---@param config java.Config
function M:run(config)
	if not config.checks.nvim_jdtls_conflict then
		return
	end

	local ok = pcall(require, 'jdtls')
	if ok then
		local err = require('java-core.utils.errors')
		err.throw([[
				nvim-jdtls plugin detected!
				nvim-java and nvim-jdtls should not be used together.
				Please remove nvim-jdtls from your configuration.
			]])
	end
end

return M
