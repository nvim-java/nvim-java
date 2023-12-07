local M = {}

function M.close_lazy_if_opened()
	local ok, view = pcall(require, 'lazy.view')

	if not ok then
		return
	end

	if not view.view then
		return
	end

	view.view:hide()
end

return M
