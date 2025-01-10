local log = require('java.utils.log')
local buf_util = require('java.utils.buffer')
local win_util = require('java.utils.window')

local async = require('java-core.utils.async').sync
local notify = require('java-core.utils.notify')

local DapSetup = require('java-dap.api.setup')
local DapRunner = require('java-dap.api.runner')

local JavaCoreTestApi = require('java-core.api.test')
local profile_config = require('java.api.profile_config')

---@class JavaDap
---@field private client LspClient
---@field private dap JavaCoreDap
---@field private test_api java_core.TestApi
---@field private test_client java-core.TestClient
local M = {}

---@param args { client: LspClient }
---@return JavaDap
function M:new(args)
	local o = {
		client = args.client,
	}

	o.test_api = JavaCoreTestApi:new({
		client = args.client,
		runner = DapRunner(),
	})

	o.dap = DapSetup(args.client)

	setmetatable(o, self)
	self.__index = self
	return o
end

---Run the current test class
---@param report java_test.JUnitTestReport
---@param config JavaCoreDapLauncherConfigOverridable
function M:execute_current_test_class(report, config)
	log.debug('running the current class')

	return self.test_api:run_class_by_buffer(
		buf_util.get_curr_buf(),
		report,
		config
	)
end

function M:execute_current_test_method(report, config)
	log.debug('running the current method')

	local method = self:find_current_test_method()

	if not method then
		notify.warn('cursor is not on a test method')
		return
	end

	self.test_api:run_test({ method }, report, config)
end

function M:find_current_test_method()
	log.debug('finding the current test method')

	local cursor = win_util.get_cursor()
	local methods = self.test_api:get_test_methods(buf_util.get_curr_uri())

	for _, method in ipairs(methods) do
		local line_start = method.range.start.line
		local line_end = method.range['end'].line

		if cursor.line >= line_start and cursor.line <= line_end then
			return method
		end
	end
end

function M:config_dap()
	log.debug('set dap adapter callback function')
	local nvim_dap = require('dap')
	nvim_dap.adapters.java = function(callback)
		async(function()
			local adapter = self.dap:get_dap_adapter()
			callback(adapter --[[@as Adapter]])
		end).run()
	end
	local dap_config = self.dap:get_dap_config()

	for _, config in ipairs(dap_config) do
		local profile = profile_config.get_active_profile(config.name)
		if profile then
			config.vmArgs = profile.vm_args
			config.args = profile.prog_args
		end
	end
	-- if dap is already running, need to terminate it to apply new config
	if nvim_dap.session then
		nvim_dap.terminate()
		if vim.g.nvim_java_config.notifications.dap then
			notify.warn('Terminating current dap session')
		end
	end
	-- end
	nvim_dap.configurations.java = nvim_dap.configurations.java or {}
	vim.list_extend(nvim_dap.configurations.java, dap_config)
end

return M
