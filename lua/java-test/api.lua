local log = require('java-core.utils.log2')
local notify = require('java-core.utils.notify')
local test_adapters = require('java-test.adapters')
local dap_adapters = require('java-dap.data-adapters')
local buf_util = require('java-core.utils.buffer')
local win_util = require('java.utils.window')

local DebugClient = require('java-core.ls.clients.java-debug-client')
local TestClient = require('java-core.ls.clients.java-test-client')

---@class java_test.TestApi
---@field private client java-core.JdtlsClient
---@field private debug_client java-core.DebugClient
---@field private test_client java-core.TestClient
---@field private runner java-dap.DapRunner
local M = {}

---Returns a new test helper client
---@param args { client: vim.lsp.Client, runner: java-dap.DapRunner }
---@return java_test.TestApi
function M:new(args)
	local o = {
		client = args.client,
	}

	o.debug_client = DebugClient(args.client)
	o.test_client = TestClient(args.client)
	o.runner = args.runner

	setmetatable(o, self)
	self.__index = self

	return o
end

---Returns a list of test methods
---@param file_uri string uri of the class
---@return java-core.TestDetailsWithRange[] # list of test methods
function M:get_test_methods(file_uri)
	log.debug('finding test methods for uri: ' .. file_uri)

	local classes = self.test_client:find_test_types_and_methods(file_uri)
	local methods = {}

	for _, class in ipairs(classes) do
		for _, method in ipairs(class.children) do
			---@diagnostic disable-next-line: inject-field
			method.class = class
			table.insert(methods, method)
		end
	end

	log.debug('found ' .. #methods .. ' test methods')

	return methods
end

---comment
---@param buffer number
---@param report java-test.JUnitTestReport
---@param config? java-dap.DapLauncherConfigOverridable config to override the default values in test launcher config
function M:run_class_by_buffer(buffer, report, config)
	log.debug('running test class from buffer: ' .. buffer)

	local tests = self:get_test_class_by_buffer(buffer)

	if #tests < 1 then
		notify.warn('No tests found in the current buffer')
		return
	end

	log.debug('found ' .. #tests .. ' test classes')

	self:run_test(tests, report, config)
end

---Returns test classes in the given buffer
---@private
---@param buffer integer
---@return java-core.TestDetailsWithChildrenAndRange # get test class details
function M:get_test_class_by_buffer(buffer)
	log.debug('finding test class by buffer')

	local uri = vim.uri_from_bufnr(buffer)
	return self.test_client:find_test_types_and_methods(uri)
end

---Run the given test
---@param tests java-core.TestDetails[]
---@param report java-test.JUnitTestReport
---@param config? java-dap.DapLauncherConfigOverridable config to override the default values in test launcher config
function M:run_test(tests, report, config)
	log.debug('running ' .. #tests .. ' tests')

	local launch_args = self.test_client:resolve_junit_launch_arguments(test_adapters.tests_to_junit_launch_params(tests))

	log.debug(
		'resolved launch args - mainClass: ' .. launch_args.mainClass .. ', projectName: ' .. launch_args.projectName
	)

	local java_exec = self.debug_client:resolve_java_executable(launch_args.mainClass, launch_args.projectName)

	log.debug('java executable: ' .. vim.inspect(java_exec))

	local dap_launcher_config = dap_adapters.junit_launch_args_to_dap_config(launch_args, java_exec, {
		debug = true,
		label = 'Launch All Java Tests',
	})

	dap_launcher_config = vim.tbl_deep_extend('force', dap_launcher_config, config or {})

	log.debug('launching tests with config: ' .. vim.inspect(dap_launcher_config))

	self.runner:run_by_config(dap_launcher_config, report)
end

---Run the current test class
---@param report java-test.JUnitTestReport
---@param config java-dap.DapLauncherConfigOverridable
function M:execute_current_test_class(report, config)
	log.debug('running the current class')

	return self:run_class_by_buffer(buf_util.get_curr_buf(), report, config)
end

---Run the current test method
---@param report java-test.JUnitTestReport
---@param config java-dap.DapLauncherConfigOverridable
function M:execute_current_test_method(report, config)
	log.debug('running the current method')

	local method = self:find_current_test_method()

	if not method then
		notify.warn('cursor is not on a test method')
		return
	end

	self:run_test({ method }, report, config)
end

---Find the test method at the current cursor position
---@return java-core.TestDetailsWithRange | nil
function M:find_current_test_method()
	log.debug('finding the current test method')

	local cursor = win_util.get_cursor()
	local methods = self:get_test_methods(buf_util.get_curr_uri())

	for _, method in ipairs(methods) do
		local line_start = method.range.start.line
		local line_end = method.range['end'].line

		if cursor.line >= line_start and cursor.line <= line_end then
			return method
		end
	end
end

return M
