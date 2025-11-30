local class = require('java-core.utils.class')
local TestParser = require('java-test.results.result-parser')

---@class java-test.TestParserFactory
local TestParserFactory = class()

---Returns a test parser of given type
---@return java-test.TestParser
function TestParserFactory:get_parser()
	return TestParser()
end

return TestParserFactory
