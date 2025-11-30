local List = require('java-core.utils.list')
local Set = require('java-core.utils.set')

local M = {}

---Returns the dap config record
---@param main java-dap.JavaDebugResolveMainClassRecord
---@return java-dap.DapLauncherConfig
function M.main_to_dap_launch_config(main)
	local project_name = main.projectName
	local main_class = main.mainClass

	return {
		request = 'launch',
		type = 'java',
		name = string.format('%s -> %s', project_name, main_class),
		projectName = project_name,
		mainClass = main_class,
	}
end

---Returns the launcher config
---@param launch_args java-core.JavaCoreTestJunitLaunchArguments
---@param java_exec string
---@param config { debug: boolean, label: string }
---@return java-dap.DapLauncherConfig
function M.junit_launch_args_to_dap_config(launch_args, java_exec, config)
	return {
		name = config.label,
		type = 'java',
		request = 'launch',
		mainClass = launch_args.mainClass,
		projectName = launch_args.projectName,
		noDebug = not config.debug,
		javaExec = java_exec,
		cwd = launch_args.workingDirectory,
		classPaths = Set:new(launch_args.classpath),
		modulePaths = Set:new(launch_args.modulepath),
		vmArgs = List:new(launch_args.vmArguments):join(' '),
		args = List:new(launch_args.programArguments):join(' '),
	}
end

return M
