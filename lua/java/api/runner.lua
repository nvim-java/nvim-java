local log = require('java.utils.log')
local async = require('java-core.utils.async').sync
local get_error_handler = require('java.handlers.error')
local jdtls = require('java.utils.jdtls')
local DapSetup = require('java-dap.api.setup')
local ui = require('java.utils.ui')
local profile_config = require('java.api.profile_config')
local class = require('java-core.utils.class')

local group = vim.api.nvim_create_augroup('logger', { clear = true })

--- @class RunnerApi
--- @field client LspClient
--- @field private dap java.DapSetup
local RunnerApi = class()

function RunnerApi:_init(args)
	self.client = args.client
	self.dap = DapSetup(args.client)
end

function RunnerApi:get_config()
	local configs = self.dap:get_dap_config()
	return ui.select_from_dap_configs(configs)
end

--- @param callback fun(cmd, config)
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

	local active_profile =
		profile_config.get_active_profile(enrich_config.mainClass)

	local vm_args = ''
	local prog_args = ''
	if active_profile then
		prog_args = (active_profile.prog_args or '') .. ' ' .. (args or '')
		vm_args = active_profile.vm_args or ''
	end

	local cmd = {
		java_exec,
		vm_args,
		'-cp',
		class_paths,
		main_class,
		prog_args,
	}
	log.debug('run app cmd: ', cmd)
	callback(cmd, config)
end

--- @class RunningApp
--- @field win  number
--- @field bufnr number
--- @field job_id number
--- @field chan number
--- @field dap_config table
--- @field is_open boolean
--- @field running_status string
local RunningApp = class()

--- @param dap_config table
function RunningApp:_init(dap_config)
	self.is_open = false
	self.dap_config = dap_config
	self.bufnr = vim.api.nvim_create_buf(false, true)
end

--- @class BuiltInMainRunner
--- @field running_apps table<string, RunningApp>
--- @field current_app RunningApp
local BuiltInMainRunner = class()

function BuiltInMainRunner:_init()
	self.running_apps = {}
	self.current_app = nil
end

--- @param running_app RunningApp
function BuiltInMainRunner.set_up_buffer_autocmd(running_app)
	vim.api.nvim_create_autocmd({ 'BufHidden' }, {
		group = group,
		buffer = running_app.bufnr,
		callback = function(_)
			running_app.is_open = false
		end,
	})
end

--- @param running_app RunningApp
function BuiltInMainRunner.stop(running_app)
	if running_app.job_id ~= nil then
		vim.fn.jobstop(running_app.job_id)
		vim.fn.jobwait({ running_app.job_id }, 1000)
		running_app.job_id = nil
	end
end

--- @param running_app RunningApp
function BuiltInMainRunner.set_up_buffer(running_app)
	vim.cmd('sp | winc J | res 15 | buffer ' .. running_app.bufnr)
	running_app.win = vim.api.nvim_get_current_win()

	vim.wo[running_app.win].number = false
	vim.wo[running_app.win].relativenumber = false
	vim.wo[running_app.win].signcolumn = 'no'

	BuiltInMainRunner.set_up_buffer_autocmd(running_app)
	running_app.is_open = true
end

--- @param exit_code number
--- @param running_app RunningApp
function BuiltInMainRunner.on_exit(exit_code, running_app)
	local exit_message = 'Process finished with exit code ' .. exit_code
	vim.fn.chansend(running_app.chan, '\n' .. exit_message .. '\n')
	local current_buf = vim.api.nvim_get_current_buf()
	if current_buf == running_app.bufnr then
		vim.cmd('stopinsert')
	end
	vim.notify(running_app.dap_config.name .. ' ' .. exit_message)
	running_app.running_status = exit_message
end

--- @param running_app RunningApp
function BuiltInMainRunner.scroll_down(running_app)
	local last_line = vim.api.nvim_buf_line_count(running_app.bufnr)
	vim.api.nvim_win_set_cursor(running_app.win, { last_line, 0 })
end

--- @param running_app RunningApp
function BuiltInMainRunner.hide_logs(running_app)
	if not running_app or not running_app.is_open then
		return
	end
	if running_app.bufnr then
		vim.api.nvim_buf_call(running_app.bufnr, function()
			vim.cmd('hide')
		end)
	end
end

--- @param running_app RunningApp
function BuiltInMainRunner.toggle_logs(running_app)
	if running_app and not running_app.is_open then
		vim.api.nvim_buf_call(running_app.bufnr, function()
			BuiltInMainRunner.set_up_buffer(running_app)
			BuiltInMainRunner.scroll_down(running_app)
		end)
	else
		BuiltInMainRunner.hide_logs(running_app)
	end
end

function BuiltInMainRunner:toggle_current_app_logs()
	local running_app = self.current_app
	if not running_app then
		return
	end
	BuiltInMainRunner.toggle_logs(running_app)
end

--- @param data string[]
--- @param running_app RunningApp
function BuiltInMainRunner.on_stdout(data, running_app)
	vim.fn.chansend(running_app.chan, data)
	if not running_app.is_open then
		return
	end
	vim.api.nvim_buf_call(running_app.bufnr, function()
		local current_buf = vim.api.nvim_get_current_buf()
		local mode = vim.api.nvim_get_mode().mode
		if current_buf ~= running_app.bufnr or mode ~= 'i' then
			BuiltInMainRunner.scroll_down(running_app)
		end
	end)
end

--- @param cmd string[]
--- @param config table
function BuiltInMainRunner:run_app(cmd, config)
	local selected_app = self:select_app_with_dap_config(config)
	if self.current_app then
		if self.current_app.job_id == selected_app.job_id then
			BuiltInMainRunner.stop(selected_app)
		end
	end
	self:change_current_app(selected_app)
	if not selected_app.is_open or not selected_app.chan then
		vim.api.nvim_buf_call(selected_app.bufnr, function()
			BuiltInMainRunner.set_up_buffer(selected_app)
			BuiltInMainRunner.scroll_down(selected_app)
		end)
		vim.api.nvim_buf_set_name(selected_app.bufnr, selected_app.dap_config.name)
	end

	selected_app.chan = vim.api.nvim_open_term(selected_app.bufnr, {
		on_input = function(_, _, _, data)
			if selected_app.job_id then
				vim.fn.chansend(selected_app.job_id, data)
			end
		end,
	})

	selected_app.running_status = '(running)'
	local command = table.concat(cmd, ' ')
	vim.fn.chansend(selected_app.chan, command)
	selected_app.job_id = vim.fn.jobstart(command, {
		pty = true,
		on_stdout = function(_, data)
			BuiltInMainRunner.on_stdout(data, selected_app)
		end,
		on_exit = function(_, exit_code)
			BuiltInMainRunner.on_exit(exit_code, selected_app)
		end,
	})
end

--- @return RunningApp|nil
function BuiltInMainRunner:select_app_with_ui()
	--- @type RunningApp
	local app = nil
	local count = 0
	for _ in pairs(self.running_apps) do
		count = count + 1
	end
	if count == 0 then
		error('No running apps')
	elseif count == 1 then
		for _, _app in pairs(self.running_apps) do
			app = _app
		end
	else
		local configs = {}
		for _, _app in pairs(self.running_apps) do
			_app.dap_config.extra_args = _app.running_status
			table.insert(configs, _app.dap_config)
		end

		local selected = ui.select_from_dap_configs(configs)
		if not selected then
			return nil
		end
		app = self.running_apps[selected.mainClass]
	end
	self:change_current_app(app)
	return app
end

--- @param app RunningApp
function BuiltInMainRunner:change_current_app(app)
	if
		self.current_app
		and self.current_app.dap_config.name ~= app.dap_config.name
	then
		BuiltInMainRunner.hide_logs(self.current_app)
	end
	self.current_app = app
end

--- @param config table|nil
--- @return RunningApp
function BuiltInMainRunner:select_app_with_dap_config(config)
	--- @type RunningApp
	if not config then
		error('No config')
	end

	if self.running_apps and self.running_apps[config.mainClass] then
		return self.running_apps[config.mainClass]
	end
	local running_app = RunningApp(config)
	self.running_apps[running_app.dap_config.mainClass] = running_app
	return running_app
end

function BuiltInMainRunner:switch_app()
	local selected_app = self:select_app_with_ui()
	if not selected_app then
		return
	end
	if not selected_app.is_open then
		BuiltInMainRunner.toggle_logs(selected_app)
	end
end

function BuiltInMainRunner:stop_app()
	local selected_app = self:select_app_with_ui()
	if not selected_app then
		return
	end
	BuiltInMainRunner.stop(selected_app)
	BuiltInMainRunner.toggle_logs(selected_app)
end

local M = {
	built_in = {},
	--- @type BuiltInMainRunner
	runner = BuiltInMainRunner(),
}

--- @param callback fun(cmd, config)
--- @param args string
function M.run_app(callback, args)
	return async(function()
			return RunnerApi(jdtls()):run_app(callback, args)
		end)
		.catch(get_error_handler('failed to run app'))
		.run()
end

--- @param opts {}
function M.built_in.run_app(opts)
	async(function()
			M.run_app(function(cmd, config)
				M.runner:run_app(cmd, config)
			end, opts.args)
		end)
		.catch(get_error_handler('failed to run app'))
		.run()
end

function M.built_in.toggle_logs()
	async(function()
			M.runner:toggle_current_app_logs()
		end)
		.catch(get_error_handler('failed to toggle logs'))
		.run()
end

function M.built_in.switch_app()
	async(function()
			M.runner:switch_app()
		end)
		.catch(get_error_handler('failed to switch app'))
		.run()
end

function M.built_in.stop_app()
	async(function()
			M.runner:stop_app()
		end)
		.catch(get_error_handler('failed to stop app'))
		.run()
end

M.RunnerApi = RunnerApi
M.BuiltInMainRunner = BuiltInMainRunner
M.RunningApp = RunningApp

return M
