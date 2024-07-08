local class = require('java-core.utils.class')
local notify = require('java-core.utils.notify')

---@class java.Run
---@field name string
---@field main_class string
---@field buffer number
---@field is_running boolean
---@field is_manually_stoped boolean
---@field private cmd string
---@field private term_chan_id number
---@field private job_chan_id number | nil
---@field private is_failure boolean
local Run = class()

---@param dap_config java-dap.DapLauncherConfig
---@param cmd string[]
function Run:_init(dap_config, cmd)
	self.name = dap_config.name
	self.main_class = dap_config.mainClass
	self.cmd = table.concat(cmd, ' ')
	self.buffer = vim.api.nvim_create_buf(false, true)
	self.term_chan_id = vim.api.nvim_open_term(self.buffer, {
		on_input = function(_, _, _, data)
			self:send_job(data)
		end,
	})
end

function Run:start()
	self.is_running = true
	self:send_term(self.cmd)

	self.job_chan_id = vim.fn.jobstart(self.cmd, {
		pty = true,
		on_stdout = function(_, data)
			self:send_term(data)
		end,
		on_exit = function(_, exit_code)
			self:on_job_exit(exit_code)
		end,
	})
end

function Run:stop()
	if not self.job_chan_id then
		return
	end

	self.is_manually_stoped = true
	vim.fn.jobstop(self.job_chan_id)
	vim.fn.jobwait({ self.job_chan_id }, 1000)
	self.job_chan_id = nil
end

---Send data to execution job channel
---@private
---@param data string
function Run:send_job(data)
	if self.job_chan_id then
		vim.fn.chansend(self.job_chan_id, data)
	end
end

---Send message to terminal channel
---@private
---@param data string
function Run:send_term(data)
	vim.fn.chansend(self.term_chan_id, data)
end

---Runs when the current job exists
---@private
---@param exit_code number
function Run:on_job_exit(exit_code)
	local message =
		string.format('Process finished with exit code::%s', exit_code)
	self:send_term(message)

	self.is_running = false

	if exit_code == 0 or self.is_manually_stoped then
		self.is_failure = false
		self.is_manually_stoped = false
	else
		self.is_failure = true
		notify.error(string.format('%s %s', self.name, message))
	end
end

return Run
