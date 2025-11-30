local java = require('java')

local function c(cmd, callback, opts)
	vim.api.nvim_create_user_command(cmd, callback, opts or {})
end

local cmd_map = {
	JavaSettingsChangeRuntime = { java.settings.change_runtime },

	JavaDapConfig = {
		function()
			require('java-dap').config_dap()
		end,
	},

	JavaTestRunCurrentClass = {
		function()
			require('java-test').run_current_class()
		end,
	},
	JavaTestDebugCurrentClass = {
		function()
			require('java-test').debug_current_class()
		end,
	},

	JavaTestRunCurrentMethod = {
		function()
			require('java-test').run_current_method()
		end,
	},
	JavaTestDebugCurrentMethod = {
		function()
			require('java-test').debug_current_method()
		end,
	},

	JavaTestViewLastReport = {
		function()
			require('java-test').view_last_report()
		end,
	},

	JavaRunnerRunMain = { java.runner.built_in.run_app, { nargs = '?' } },
	JavaRunnerStopMain = { java.runner.built_in.stop_app },
	JavaRunnerToggleLogs = { java.runner.built_in.toggle_logs },
	JavaRunnerSwitchLogs = { java.runner.built_in.switch_app },

	JavaProfile = { java.profile.ui },
}

for cmd, details in pairs(cmd_map) do
	c(cmd, details[1], details[2])
end
