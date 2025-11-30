---@enum MessageId
local MessageId = {
	-- Notification about a test inside the test suite.
	-- TEST_TREE + testId + "," + testName + "," + isSuite + "," + testCount + "," + isDynamicTest +
	-- "," + parentId + "," + displayName + "," + parameterTypes + "," + uniqueId

	-- isSuite = "true" or "false"
	-- isDynamicTest = "true" or "false"
	-- parentId = the unique id of its parent if it is a dynamic test, otherwise can be "-1"
	-- displayName = the display name of the test
	-- parameterTypes = comma-separated list of method parameter types if applicable, otherwise an
	-- empty string
	-- uniqueId = the unique ID of the test provided by JUnit launcher, otherwise an empty string

	TestTree = '%TSTTREE',
	TestStart = '%TESTS',
	TestEnd = '%TESTE',
	TestFailed = '%FAILED',
	TestError = '%ERROR',
	ExpectStart = '%EXPECTS',
	ExpectEnd = '%EXPECTE',
	ActualStart = '%ACTUALS',
	ActualEnd = '%ACTUALE',
	TraceStart = '%TRACES',
	TraceEnd = '%TRACEE',
	IGNORE_TEST_PREFIX = '@Ignore: ',
	ASSUMPTION_FAILED_TEST_PREFIX = '@AssumptionFailure: ',
}

return MessageId
