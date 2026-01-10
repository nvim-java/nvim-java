local log = require('java-core.utils.log2')
local lsp_utils = require('java-core.utils.lsp')
local get_error_handler = require('java-core.utils.error_handler')

local runner = require('async.runner')

local JavaTestApi = require('java-test.api')
local DapRunner = require('java-dap.runner')
local JUnitReport = require('java-test.reports.junit')
local ResultParserFactory = require('java-test.results.result-parser-factory')
local ReportViewer = require('java-test.ui.floating-report-viewer')

local M = {
	---@type java-test.JUnitTestReport
	last_report = nil,
}

function M.run_current_class()
	log.info('run current test class')

	return runner(function()
			local test_api = JavaTestApi:new({
				client = lsp_utils.get_jdtls(),
				runner = DapRunner(),
			})
			return test_api:execute_current_test_class(M.get_report(), { noDebug = true })
		end)
		.catch(get_error_handler('failed to run the current test class'))
		.run()
end

function M.debug_current_class()
	log.info('debug current test class')

	return runner(function()
			local test_api = JavaTestApi:new({
				client = lsp_utils.get_jdtls(),
				runner = DapRunner(),
			})
			test_api:execute_current_test_class(M.get_report(), {})
		end)
		.catch(get_error_handler('failed to debug the current test class'))
		.run()
end

function M.debug_current_method()
	log.info('debug current test method')

	return runner(function()
			local test_api = JavaTestApi:new({
				client = lsp_utils.get_jdtls(),
				runner = DapRunner(),
			})
			return test_api:execute_current_test_method(M.get_report(), {})
		end)
		.catch(get_error_handler('failed to run the current test method'))
		.run()
end

function M.run_current_method()
	log.info('run current test method')

	return runner(function()
			local test_api = JavaTestApi:new({
				client = lsp_utils.get_jdtls(),
				runner = DapRunner(),
			})
			return test_api:execute_current_test_method(M.get_report(), { noDebug = true })
		end)
		.catch(get_error_handler('failed to run the current test method'))
		.run()
end

function M.run_all_tests()
	log.info('run all tests')

	return runner(function()
			local test_api = JavaTestApi:new({
				client = lsp_utils.get_jdtls(),
				runner = DapRunner(),
			})
			return test_api:execute_all_tests(M.get_report(), { noDebug = true })
		end)
		.catch(get_error_handler('failed to run all tests'))
		.run()
end

function M.debug_all_tests()
	log.info('debug all tests')

	return runner(function()
			local test_api = JavaTestApi:new({
				client = lsp_utils.get_jdtls(),
				runner = DapRunner(),
			})
			return test_api:execute_all_tests(M.get_report(), {})
		end)
		.catch(get_error_handler('failed to debug all tests'))
		.run()
end

function M.view_last_report()
	if M.last_report then
		M.last_report:show_report()
	end
end

---@private
function M.get_report()
	local report = JUnitReport(ResultParserFactory(), ReportViewer())
	M.last_report = report
	return report
end

return M
