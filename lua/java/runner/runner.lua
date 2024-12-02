local ui = require('java.utils.ui')
local class = require('java-core.utils.class')
local jdtls = require('java.utils.jdtls2')
local profile_config = require('java.api.profile_config')
local Run = require('java.runner.run')
local RunLogger = require('java.runner.run-logger')
local DapSetup = require('java-dap.api.setup')

---@class java.Runner
---@field runs table<string, java.Run>
---@field logger java.RunLogger
local Runner = class()

function Runner:_init()
	self.runs = {}
	self.curr_run = nil
	self.logger = RunLogger()
end

---Starts a new run
---@param args string
function Runner:start_run(args)
	local cmd, dap_config = Runner.select_dap_config(args)

	if not cmd or not dap_config then
		return
	end

	local run = self.runs[dap_config.mainClass]

	-- get the default run if exist or create new run
	if run then
		if run.is_running then
			run:stop()
		end
	else
		run = Run(dap_config, cmd)
		self.runs[dap_config.mainClass] = run
	end

	self.curr_run = run
	self.logger:set_buffer(run.buffer)

	run:start(cmd)
end

---Stops the user selected run
function Runner:stop_run()
	local run = self:select_run()

	if not run then
		return
	end

	run:stop()
end

function Runner:toggle_open_log()
	if self.logger:is_opened() then
		self.logger:close()
	else
		if self.curr_run then
			self.logger:create(self.curr_run.buffer)
		end
	end
end

---Switches the log to selected run
function Runner:switch_log()
	local selected_run = self:select_run()

	if not selected_run then
		return
	end

	self.curr_run = selected_run
	self.logger:set_buffer(selected_run.buffer)
end

---Prompt the user to select an active run and returns the selected run
---@private
---@return java.Run | nil
function Runner:select_run()
	local active_main_classes = {} ---@type string[]

	for _, run in pairs(self.runs) do
		table.insert(active_main_classes, run.main_class)
	end

	local selected_main = ui.select('Select main class', active_main_classes)

	if not selected_main then
		return
	end

	return self.runs[selected_main]
end

---Returns the dap config for user selected main
---@param args string additional program arguments to pass
---@return string[] | nil
---@return java-dap.DapLauncherConfig | nil
function Runner.select_dap_config(args)
	local dap = DapSetup(jdtls())
	local dap_config_list = dap:get_dap_config()

	local selected_dap_config = ui.select(
		'Select the main class (module -> mainClass)',
		dap_config_list,
		function(config)
			return config.name
		end
	)

	if not selected_dap_config then
		return nil, nil
	end

	local enriched_config = dap:enrich_config(selected_dap_config)

	local class_paths = table.concat(enriched_config.classPaths, ':')
	local main_class = enriched_config.mainClass
	local java_exec = enriched_config.javaExec

	local active_profile = profile_config.get_active_profile(enriched_config.name)

	local vm_args = ''
	local prog_args = args

	if active_profile then
		prog_args = (active_profile.prog_args or '') .. ' ' .. (args or '')
		vm_args = active_profile.vm_args or ''
	end

	local cmd = {
		java_exec,
		vm_args,
		'-cp',
		class_paths,
		main_class,
		prog_args,
	}

	return cmd, selected_dap_config
end

return Runner
