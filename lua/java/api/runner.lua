local async = require('java-core.utils.async').sync
local get_error_handler = require('java.handlers.error')
local Runner = require('java.runner.runner')

local M = {
	built_in = {},

	---@type java.Runner
	runner = Runner(),
}

--- @param opts {}
function M.built_in.run_app(opts)
	async(function()
			M.runner:start_run(opts.args)
		end)
		.catch(get_error_handler('Failed to run app'))
		.run()
end

function M.built_in.toggle_logs()
	async(function()
			M.runner:toggle_open_log()
		end)
		.catch(get_error_handler('Failed to run app'))
		.run()
end

function M.built_in.switch_app()
	async(function()
			M.runner:switch_log()
		end)
		.catch(get_error_handler('Failed to switch run'))
		.run()
end

function M.built_in.stop_app()
	async(function()
			M.runner:stop_run()
		end)
		.catch(get_error_handler('Failed to stop run'))
		.run()
end

return M
