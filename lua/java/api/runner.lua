local log = require('java.utils.log')
local class = require('java-core.utils.class')
local async = require('java-core.utils.async')
local get_error_handler = require('java.handlers.error')
local jdtls = require('java.utils.jdtls')
local notify = require('java-core.utils.notify')
local DapSetup = require('java-dap.api.setup')

local sync = require('java-core.utils.async').sync
local wait = require('java-core.utils.async').wait

--- @class BuiltInMainRunner
--- @field win  number
--- @field bufnr number
--- @field job_id number
--- @field is_open boolean
local BuiltInMainRunner = class()

function BuiltInMainRunner:_set_up_buffer_autocmd()
	local group = vim.api.nvim_create_augroup('logger', { clear = true })
	vim.api.nvim_create_autocmd({ 'BufHidden' }, {
		group = group,
		buffer = self.bufnr,
		callback = function(_)
			self.is_open = true
		end,
	})
end

function BuiltInMainRunner:_init()
	self.is_open = false
end

function BuiltInMainRunner:stop()
	if self.job_id ~= nil then
		vim.fn.jobstop(self.job_id)
		vim.fn.jobwait({ self.job_id }, 1000)
		self.job_id = nil
	end
end

---Creates a terminal window and runs the given cmd
---@param cmd string[] command to run
function BuiltInMainRunner:run_app(cmd)
	self:stop()
	if not self.bufnr then
		self.bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_call(self.bufnr, function()
			self:_set_up_buffer()
		end)
	end

	self.chan = vim.api.nvim_open_term(self.bufnr, {
		on_input = function(_, _, _, data)
			if self.job_id then
				-- Sends the stdin to the process
				vim.fn.chansend(self.job_id, data)
			end
		end,
	})

	local command = table.concat(cmd, ' ')
	vim.fn.chansend(self.chan, command)
	self.job_id = vim.fn.jobstart(command, {
		pty = true,
		clear_env = true,
		on_stdout = function(_, data)
			self:_on_stdout(data)
		end,
		on_exit = function(_, exit_code)
			self:_on_exit(exit_code)
		end,
	})
end

---Hides the log window
function BuiltInMainRunner:hide_logs()
	if self.bufnr then
		self.is_open = true
		vim.api.nvim_buf_call(self.bufnr, function()
			vim.cmd('hide')
		end)
	end
end

---Toggles the log window
function BuiltInMainRunner:toggle_logs()
	if self.is_open then
		vim.api.nvim_buf_call(self.bufnr, function()
			self:_set_up_buffer()
			self:_scroll_down()
		end)
	else
		self:hide_logs()
	end
end

---Opens a window at the bottom of the editor and sets the buffer
function BuiltInMainRunner:_set_up_buffer()
	vim.cmd('sp | winc J | res 15 | buffer ' .. self.bufnr)
	self.win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_option(self.win, 'number', false)
	vim.api.nvim_win_set_option(self.win, 'relativenumber', false)
	vim.api.nvim_win_set_option(self.win, 'signcolumn', 'no')
	self:_set_up_buffer_autocmd()
	self.is_open = false
end

---@param data string[]
function BuiltInMainRunner:_on_stdout(data)
	vim.fn.chansend(self.chan, data)
	vim.api.nvim_buf_call(self.bufnr, function()
		local current_buf = vim.api.nvim_get_current_buf()
		local mode = vim.api.nvim_get_mode().mode
		if current_buf ~= self.bufnr or mode ~= 'i' then
			self:_scroll_down()
		end
	end)
end

--- @param exit_code number
function BuiltInMainRunner:_on_exit(exit_code)
	vim.fn.chansend(
		self.chan,
		'\nProcess finished with exit code ' .. exit_code .. '\n'
	)
	self.job_id = nil
	local current_buf = vim.api.nvim_get_current_buf()
	if current_buf == self.bufnr then
		vim.cmd('stopinsert')
	end
end

function BuiltInMainRunner:_scroll_down()
	local last_line = vim.api.nvim_buf_line_count(self.bufnr)
	vim.api.nvim_win_set_cursor(self.win, { last_line, 0 })
end

--- @class RunnerApi
--- @field client LspClient
--- @field private dap JavaCoreDap
local RunnerApi = class()

function RunnerApi:_init(args)
	self.client = args.client
	self.dap = DapSetup(args.client)
end

function RunnerApi:get_config()
	local configs = self.dap:get_dap_config()
	log.debug('dap configs: ', configs)

	local config_names = {}
	local config_lookup = {}
	for _, config in ipairs(configs) do
		if config.projectName then
			table.insert(config_names, config.name)
			config_lookup[config.name] = config
		end
	end

	if #config_names == 0 then
		notify.warn('Dap config not found')
		return
	end

	if #config_names == 1 then
		return config_lookup[config_names[1]]
	end

	local selected_key = self:_ui_select_sync(config_names, {
		prompt = 'Select the main class (module -> mainClass)',
	})

	vim.print('selected_key', selected_key)
	return config_lookup[selected_key]
end

function RunnerApi:_ui_select_sync(items, opts)
	return wait(function(callback)
		vim.ui.select(items, opts, callback)
	end)
end

--- @param callback fun(cmd)
--- @param args string
function RunnerApi:run_app(callback, args)
	local config = self:get_config()
	if not config then
		return
	end

	config.request = 'launch'
	local enrich_config = self.dap:enrich_config(config)
	local class_paths = table.concat(enrich_config.classPaths, ':')
	local main_class = enrich_config.mainClass
	local java_exec = enrich_config.javaExec

	local cmd = {
		java_exec,
		args or '',
		'-cp',
		class_paths,
		main_class,
	}
	log.debug('run app cmd: ', cmd)
	callback(cmd)
end

local M = {
	built_in = {},
}

--- @param callback fun(cmd)
--- @param args string
function M.run_app(callback, args)
	return sync(function()
			return RunnerApi(jdtls()):run_app(callback, args)
		end)
		.catch(get_error_handler('failed to run app'))
		.run()
end

--- @param opts {}
function M.built_in.run_app(opts)
	sync(function()
		if not M.BuildInRunner then
			M.BuildInRunner = BuiltInMainRunner()
		end

		M.run_app(function(cmd)
			M.BuildInRunner:run_app(cmd)
		end, opts.args)
	end).run()
end

function M.built_in.toggle_logs()
	if M.BuildInRunner then
		M.BuildInRunner:toggle_logs()
	end
end

function M.built_in.stop_app()
	if M.BuildInRunner then
		M.BuildInRunner:stop(false)
	end
end

M.RunnerApi = RunnerApi
M.BuiltInMainRunner = BuiltInMainRunner
return M
