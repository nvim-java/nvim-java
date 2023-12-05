local java = require('java')

local function c(cmd, callback, opts)
	vim.api.nvim_create_user_command(cmd, callback, opts or {})
end

local cmd_map = {
	JavaDapConfig = { java.dap.config_dap },

	JavaTestRunCurrentClass = { java.test.run_current_class },
	JavaTestDebugCurrentClass = { java.test.debug_current_class },

	JavaTestRunCurrentMethod = { java.test.run_current_method },
	JavaTestDebugCurrentMethod = { java.test.debug_current_method },

	JavaTestViewLastReport = { java.test.view_last_report },
}

for cmd, details in pairs(cmd_map) do
	c(cmd, details[1], details[2])
end
