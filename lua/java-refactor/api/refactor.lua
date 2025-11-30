---@param action_type string
---@param filter? string
local function run_code_action(action_type, filter)
	vim.lsp.buf.code_action({
		apply = true,
		context = {
			diagnostics = vim.lsp.diagnostic.get_line_diagnostics(0),
			only = { action_type },
		},
		filter = filter and function(refactor)
			return refactor.command.arguments[1] == filter
		end or nil,
	})
end

local M = {
	extract_variable = function()
		run_code_action('refactor.extract.variable', 'extractVariable')
	end,

	extract_variable_all_occurrence = function()
		run_code_action('refactor.extract.variable', 'extractVariableAllOccurrence')
	end,

	extract_constant = function()
		run_code_action('refactor.extract.constant')
	end,

	extract_method = function()
		run_code_action('refactor.extract.function')
	end,

	extract_field = function()
		run_code_action('refactor.extract.field')
	end,
}

return M
