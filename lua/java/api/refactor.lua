local jdtls = require('java.utils.jdtls2')
local get_error_handler = require('java.handlers.error')

local async = require('java-core.utils.async').sync

local M = {}

function M.extract_variable()
	M.extract('extractVariable')
end

function M.extract_variable_all_occurrence()
	M.extract('extractVariableAllOccurrence')
end

function M.extract_constant()
	M.extract('extractConstant')
end

function M.extract_method()
	M.extract('extractMethod')
end

function M.extract_field()
	M.extract('extractField')
end

function M.convert_variable_to_field()
	M.extract('convertVariableToField')
end

---
---@param refactor_command jdtls.CodeActionCommand
function M.extract(refactor_command)
	return async(function()
			local RefactorCommands = require('java-refactor.refactor-commands')
			local refactor_commands = RefactorCommands(jdtls())
			refactor_commands:refactor(refactor_command)
		end)
		.catch(get_error_handler('failed to refactor variable'))
		.run()
end

return M
