local log = require('java.utils.log')
local async = require('java-core.utils.async').sync
local buf_util = require('java.utils.buffer')
local win_util = require('java.utils.window')
local notify = require('java-core.utils.notify')

local JavaCoreDap = require('java-core.dap')
local JavaCoreTestApi = require('java-core.api.test')
local JavaCoreTestClient = require('java-core.ls.clients.java-test-client')
local JavaCoreDapRunner = require('java-core.dap.runner')
local JavaTestTestReporter = require('java-test.reports.junit')

---@class JavaDap
---@field private client LspClient
---@field private dap JavaCoreDap
---@field private test_api java_core.TestApi
---@field private test_client java_core.TestClient
local M = {}

---@param args { client: LspClient }
---@return JavaDap
function M:new(args)
	local o = {
		client = args.client,
	}

	o.test_api = JavaCoreTestApi:new({
		client = args.client,
		runner = JavaCoreDapRunner:new({
			reporter = JavaTestTestReporter(),
		}),
	})

	o.test_client = JavaCoreTestClient:new({
		client = args.client,
	})

	o.dap = JavaCoreDap:new({
		client = args.client,
	})

	setmetatable(o, self)
	self.__index = self
	return o
end

---Run the current test class
---@param config JavaCoreDapLauncherConfigOverridable
function M:execute_current_test_class(config)
	log.debug('running the current class')

	return self.test_api:run_class_by_buffer(buf_util.get_curr_buf(), config)
end

function M:execute_current_test_method(config)
	log.debug('running the current method')

	local method = self:find_current_test_method()

	if not method then
		notify.warn('cursor is not on a test method')
		return
	end

	self.test_api:run_test({ method }, config)
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

	require('dap').adapters.java = function(callback)
		async(function()
			local adapter = self.dap:get_dap_adapter()
			callback(adapter --[[@as Adapter]])
		end).run()
	end

	local dap_config = self.dap:get_dap_config()

	log.debug('set dap config: ', dap_config)
	require('dap').configurations.java = dap_config
end

return M
