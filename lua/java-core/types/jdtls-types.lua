local M = {}

---@enum java-core.CompileWorkspaceStatus
M.CompileWorkspaceStatus = {
	FAILED = 0,
	SUCCEED = 1,
	WITHERROR = 2,
	CANCELLED = 3,
}

return M
