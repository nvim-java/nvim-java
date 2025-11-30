local runner = require('async.runner')
local get_error_handler = require('java-core.utils.error_handler')
local Runner = require('java-runner.runner')

local M = {
	built_in = {},

	---@type java.Runner
	runner = Runner(),
}

--- @param opts {}
function M.built_in.run_app(opts)
	runner(function()
			M.runner:start_run(opts.args)
		end)
		.catch(get_error_handler('Failed to run app'))
		.run()
end

function M.built_in.toggle_logs()
	runner(function()
			M.runner:toggle_open_log()
		end)
		.catch(get_error_handler('Failed to run app'))
		.run()
end

function M.built_in.switch_app()
	runner(function()
			M.runner:switch_log()
		end)
		.catch(get_error_handler('Failed to switch run'))
		.run()
end

function M.built_in.stop_app()
	runner(function()
			M.runner:stop_run()
		end)
		.catch(get_error_handler('Failed to stop run'))
		.run()
end

return M
