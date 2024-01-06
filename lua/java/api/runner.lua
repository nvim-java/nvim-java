local log = require('java.utils.log')
local async = require('java-core.utils.async').sync
local get_error_handler = require('java.handlers.error')
local jdtls = require('java.utils.jdtls')
local notify = require('java-core.utils.notify')

local DapSetup = require('java-dap.api.setup')

--- @class BuiltInMainRunner
--- @field win  number
--- @field bufnr number
--- @field job_id number
--- @field is_open boolean
local BuiltInMainRunner = {}

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

function BuiltInMainRunner:new()
	local o = {
		is_open = false,
	}

	setmetatable(o, self)
	self.__index = self
	return o
end

--- @param clear_buffer boolean
function BuiltInMainRunner:stop(clear_buffer)
	if self.job_id ~= nil then
		vim.fn.jobstop(self.job_id)
		vim.api.nvim_buf_set_lines(
			self.bufnr,
			-2,
			-1,
			false,
			{ 'Process successfully killed.', ' ', ' ' }
		)
		self.job_id = nil
		if clear_buffer then
			vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, false, {})
		end
	end
end

function BuiltInMainRunner:_set_up_buffer()
	vim.cmd('sp | winc J | res 15 | buffer ' .. self.bufnr)
	self.win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_option(self.win, 'number', false)
	vim.api.nvim_win_set_option(self.win, 'relativenumber', false)
	vim.api.nvim_win_set_option(self.win, 'signcolumn', 'no')
	self:_set_up_buffer_autocmd()
	self.is_open = false
end

function BuiltInMainRunner:_on_std(_, data, _)
	vim.api.nvim_buf_set_lines(self.bufnr, -2, -1, false, data)
	local current_buf = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_call(self.bufnr, function()
		local mode = vim.api.nvim_get_mode().mode
		if current_buf ~= self.bufnr or mode ~= 'i' then
			vim.cmd('normal! G')
		end
	end)
end

--- @param cmd string[]
function BuiltInMainRunner:run_app(cmd)
	self:stop(true)
	if not self.bufnr then
		self.bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_call(self.bufnr, function()
			self:_set_up_buffer()
		end)
	end

	local command = table.concat(cmd, ' ')
	vim.api.nvim_buf_set_lines(self.bufnr, -2, -1, false, { command, ' ' })
	self.job_id = vim.fn.jobstart(command, {
		on_stdout = function(_, data, _)
			self:_on_std(_, data, _)
		end,
		on_stderr = function(_, data, _)
			self:_on_std(_, data, _)
		end,
	})
end

function BuiltInMainRunner:hide_logs()
	if self.bufnr then
		self.is_open = true
		vim.api.nvim_buf_call(self.bufnr, function()
			vim.cmd('hide')
		end)
	end
end

function BuiltInMainRunner:toogle_logs()
	if self.is_open then
		vim.api.nvim_buf_call(self.bufnr, function()
			self:_set_up_buffer()
			vim.cmd('normal! G')
		end)
	else
		self:hide_logs()
	end
end

--- @class RunnerApi
--- @field client LspClient
--- @field private dap JavaCoreDap
local RunnerApi = {}

function RunnerApi:new(args)
	local o = {
		client = args.client,
	}

	o.dap = DapSetup(args.client)
	setmetatable(o, self)
	self.__index = self
	return o
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

	local selected_config = nil
	vim.ui.select(config_names, {
		prompt = 'Select the main class (modul -> mainClass)',
	}, function(choice)
		selected_config = config_lookup[choice]
	end)
	return selected_config
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
	return async(function()
			return RunnerApi:new(jdtls()):run_app(callback, args)
		end)
		.catch(get_error_handler('failed to run app'))
		.run()
end

--- @param opts {}
function M.built_in.run_app(opts)
	if not M.BuildInRunner then
		M.BuildInRunner = BuiltInMainRunner:new()
	end
	M.run_app(function(cmd)
		M.BuildInRunner:run_app(cmd)
	end, opts.args)
end

function M.built_in.toogle_logs()
	if M.BuildInRunner then
		M.BuildInRunner:toogle_logs()
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
