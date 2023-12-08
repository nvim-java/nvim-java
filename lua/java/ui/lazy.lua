local M = {}

function M.close_lazy_if_opened()
	local ok, view = pcall(require, 'lazy.view')

	if not ok then
		return
	end

	if not view.view or not view.view.hide then
		return
	end

	view.view:hide()
end

return M
