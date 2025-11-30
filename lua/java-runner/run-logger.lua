local class = require('java-core.utils.class')

---@class java.RunLogger
---@field window number
local RunLogger = class()

function RunLogger:_init()
	self.window = -1
end

---Opens the log window with the given run buffer
---@param buffer number
function RunLogger:create(buffer)
	vim.cmd('sp | winc J | res 15 | buffer ' .. buffer)
	self.window = vim.api.nvim_get_current_win()

	vim.wo[self.window].number = false
	vim.wo[self.window].relativenumber = false
	vim.wo[self.window].signcolumn = 'no'

	self:scroll_to_bottom()
end

function RunLogger:set_buffer(buffer)
	if self:is_opened() then
		vim.api.nvim_win_set_buf(self.window, buffer)
	else
		self:create(buffer)
	end

	self:scroll_to_bottom()
end

function RunLogger:scroll_to_bottom()
	local buffer = vim.api.nvim_win_get_buf(self.window)
	local line_count = vim.api.nvim_buf_line_count(buffer)
	vim.api.nvim_win_set_cursor(self.window, { line_count, 0 })
end

---Returns true if the log window is opened
---@return boolean
function RunLogger:is_opened()
	if not self.window then
		return false
	end

	return vim.api.nvim_win_is_valid(self.window)
end

---Closes the log window if opened
function RunLogger:close()
	if self.window and vim.api.nvim_win_is_valid(self.window) then
		vim.api.nvim_win_hide(self.window)
	end
end

return RunLogger
