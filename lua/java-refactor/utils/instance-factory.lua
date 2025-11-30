local M = {}

---@return java-refactor.Action
function M.get_action()
	local lsp_utils = require('java-core.utils.lsp')
	local Action = require('java-refactor.action')
	local client = lsp_utils.get_jdtls()

	return Action(client)
end

return M
