local log = require('java-core.utils.log2')
local class = require('java-core.utils.class')

local JdtlsClient = require('java-core.ls.clients.jdtls-client')

---@class java-core.TestDetails
---@field fullName string
---@field id string
---@field jdtHandler string
---@field label string
---@field projectName string
---@field testKind integer
---@field testLevel integer
---@field uri string

---@class java-core.TestDetailsWithRange: java-core.TestDetails
---@field range lsp.Range

---@class java-core.TestDetailsWithChildren: java-core.TestDetails
---@field children java-core.TestDetailsWithRange[]

---@class java-core.TestDetailsWithChildrenAndRange: java-core.TestDetails
---@field range lsp.Range
---@field children java-core.TestDetailsWithRange[]

---@class java-core.TestClient: java-core.JdtlsClient
local TestClient = class(JdtlsClient)

---Returns a list of project details in the current root
---@return java-core.TestDetails[] # test details of the projects
function TestClient:find_java_projects()
	---@type java-core.TestDetails[]
	return self:workspace_execute_command(
		'vscode.java.test.findJavaProjects',
		{ vim.uri_from_fname(self.client.config.root_dir) }
	)
end

---Returns a list of test package details
---@param handler string
---@param token? string
---@return java-core.TestDetailsWithChildren[] # test package details
function TestClient:find_test_packages_and_types(handler, token)
	---@type java-core.TestDetailsWithChildren[]
	return self:workspace_execute_command('vscode.java.test.findTestPackagesAndTypes', { handler, token })
end

---Returns test informations in a given file
---@param file_uri string
---@param token? string
---@return java-core.TestDetailsWithChildrenAndRange[] # test details
function TestClient:find_test_types_and_methods(file_uri, token)
	---@type java-core.TestDetailsWithChildrenAndRange[]
	return self:workspace_execute_command('vscode.java.test.findTestTypesAndMethods', { file_uri, token })
end

---@class java-core.JavaCoreTestJunitLaunchArguments
---@field classpath string[]
---@field mainClass string
---@field modulepath string[]
---@field programArguments string[]
---@field projectName string
---@field vmArguments string[]
---@field workingDirectory string

---@class java-core.JavaCoreTestResolveJUnitLaunchArgumentsParams
---@field project_name string
---@field test_names string[]
---@field test_level java-core.TestLevel
---@field test_kind java-core.TestKind

---Returns junit launch arguments
---@param args java-core.JavaCoreTestResolveJUnitLaunchArgumentsParams
---@return java-core.JavaCoreTestJunitLaunchArguments # junit launch arguments
function TestClient:resolve_junit_launch_arguments(args)
	local launch_args = self:workspace_execute_command(
		'vscode.java.test.junit.argument',
		---@diagnostic disable-next-line: param-type-mismatch
		vim.fn.json_encode(args)
	)

	if not launch_args or not launch_args.body then
		local msg = 'Failed to retrieve JUnit launch arguments'

		log.error(msg, launch_args)
		error(msg)
	end

	return launch_args.body
end

---@enum java-core.TestKind
TestClient.TestKind = {
	JUnit5 = 0,
	JUnit = 1,
	TestNG = 2,
	None = 100,
}

---@enum java-core.TestLevel
TestClient.TestLevel = {
	Root = 0,
	Workspace = 1,
	WorkspaceFolder = 2,
	Project = 3,
	Package = 4,
	Class = 5,
	Method = 6,
	Invocation = 7,
}

return TestClient
