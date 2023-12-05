local JavaDap = require('java.dap')

local log = require('java.utils.log')
local jdtls = require('java.utils.jdtls')
local get_error_handler = require('java.handlers.error')

local async = require('java-core.utils.async').sync

local JUnitReport = require('java-test.reports.junit')
local ResultParserFactory = require('java-test.results.result-parser-factory')
local ReportViewer = require('java-test.ui.floating-report-viewer')

local M = {
	---@type java_test.JUnitTestReport
	last_report = nil,
}

---Setup dap config & adapter on jdtls attach event
function M.run_current_class()
	log.info('run current test class')

	return async(function()
			return JavaDap:new(jdtls())
				:execute_current_test_class(M.get_report(), { noDebug = true })
		end)
		.catch(get_error_handler('failed to run the current test class'))
		.run()
end

function M.debug_current_class()
	log.info('debug current test class')

	return async(function()
			JavaDap:new(jdtls()):execute_current_test_class(M.get_report(), {})
		end)
		.catch(get_error_handler('failed to debug the current test class'))
		.run()
end

function M.debug_current_method()
	log.info('debug current test method')

	return async(function()
			return JavaDap:new(jdtls())
				:execute_current_test_method(M.get_report(), {})
		end)
		.catch(get_error_handler('failed to run the current test method'))
		.run()
end

function M.run_current_method()
	log.info('run current test method')

	return async(function()
			return JavaDap:new(jdtls())
				:execute_current_test_method(M.get_report(), { noDebug = true })
		end)
		.catch(get_error_handler('failed to run the current test method'))
		.run()
end

function M.view_last_report()
	if M.last_report then
		M.last_report:show_report()
	end
end

---@private
function M.config_dap()
	log.info('configuring dap')

	return async(function()
			JavaDap:new(jdtls()):config_dap()
		end)
		.catch(get_error_handler('dap configuration failed'))
		.run()
end

---@private
function M.get_report()
	local report = JUnitReport(ResultParserFactory(), ReportViewer())
	M.last_report = report
	return report
end

return M
