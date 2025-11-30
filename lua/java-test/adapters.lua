local List = require('java-core.utils.list')
local JavaTestClient = require('java-core.ls.clients.java-test-client')

local M = {}

---Returns launch argument parameters for given test or tests
---@param tests java-core.TestDetails | java-core.TestDetails[]
---@return java-core.JavaCoreTestResolveJUnitLaunchArgumentsParams junit launch arguments
function M.tests_to_junit_launch_params(tests)
	if not vim.islist(tests) then
		return {
			projectName = tests.projectName,
			testLevel = tests.testLevel,
			testKind = tests.testKind,
			testNames = M.get_test_names({ tests }),
		}
	end

	local first_test = tests[1]

	return {
		projectName = first_test.projectName,
		testLevel = first_test.testLevel,
		testKind = first_test.testKind,
		testNames = M.get_test_names(tests),
	}
end

---Returns a list of test names to be passed to test launch arguments resolver
---@param tests java-core.TestDetails[]
---@return java-core.List
function M.get_test_names(tests)
	return List:new(tests):map(function(test)
		if test.testKind == JavaTestClient.TestKind.TestNG or test.testLevel == JavaTestClient.TestLevel.Class then
			return test.fullName
		end

		return test.jdtHandler
	end)
end

return M
