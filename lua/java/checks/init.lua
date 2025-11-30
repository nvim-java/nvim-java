local M = {}

---Run all checks
---@param config java.Config
function M.run(config)
	require('java.checks.nvim-version'):run(config)
	require('java.checks.nvim-jdtls'):run(config)
end

return M
