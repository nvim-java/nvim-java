---@class java-test.TestStatus
---@field icon string
---@field highlight string

---@type { [string]: java-test.TestStatus}
local TestStatus = {
	Failed = { icon = ' ', highlight = 'DiagnosticError' },
	Skipped = { icon = ' ', highlight = 'DiagnosticWarn' },
	Passed = { icon = ' ', highlight = 'DiagnosticOk' },
}

return TestStatus
