local class = require('java-core.utils.class')
local log = require('java-core.utils.log2')

---@class java-test.JUnitTestReport
---@field private conn uv.uv_tcp_t
---@field private result_parser java-test.TestParser
---@field private result_parser_fac java-test.TestParserFactory
---@field private report_viewer java-test.ReportViewer
---@overload fun(result_parser_factory: java-test.TestParserFactory, test_viewer: java-test.ReportViewer)
local JUnitReport = class()

---Init
---@param result_parser_factory java-test.TestParserFactory
function JUnitReport:_init(result_parser_factory, report_viewer)
	self.conn = nil
	self.result_parser_fac = result_parser_factory
	self.report_viewer = report_viewer
end

---Returns the test results
---@return java-test.TestResults[]
function JUnitReport:get_results()
	return self.result_parser:get_test_details()
end

---Shows the test report
function JUnitReport:show_report()
	self.report_viewer:show(self:get_results())
end

---Returns a stream reader function
---@param conn uv.uv_tcp_t
---@return fun(err: string, buffer: string) # callback function
function JUnitReport:get_stream_reader(conn)
	self.conn = conn
	self.result_parser = self.result_parser_fac:get_parser()

	return vim.schedule_wrap(function(err, buffer)
		if err then
			self:on_error(err)
			self:on_close()
			self.conn:close()
			return
		end

		if buffer then
			self:on_update(buffer)
		else
			self:on_close()
			self.conn:close()
		end
	end)
end

---Runs on connection update
---@private
---@param text string
function JUnitReport:on_update(text)
	self.result_parser:parse(text)
end

---Runs on connection close
---@private
function JUnitReport:on_close() end

---Runs on connection error
---@private
---@param err string error
function JUnitReport:on_error(err)
	log.error('Error while running test', err)
end

return JUnitReport
