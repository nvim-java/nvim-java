local jdtls = require('java.utils.jdtls2')
local get_error_handler = require('java.handlers.error')

local async = require('java-core.utils.async').sync

local M = {}

function M.extract_variable()
	return async(function()
			local RefactorCommands = require('java-refactor.refactor-commands')
			local refactor_commands = RefactorCommands(jdtls())
			refactor_commands:extract_variable()
		end)
		.catch(get_error_handler('failed to refactor variable'))
		.run()
end

return M
