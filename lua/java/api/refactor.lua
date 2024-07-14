local M = {}

function M.extract_variable()
	M.run_code_action('refactor.extract.variable', 'extractVariable')
end

function M.extract_variable_all_occurrence()
	M.run_code_action('refactor.extract.variable', 'extractVariableAllOccurrence')
end

function M.extract_constant()
	M.run_code_action('refactor.extract.constant')
end

function M.extract_method()
	M.run_code_action('refactor.extract.function')
end

function M.extract_field()
	M.run_code_action('refactor.extract.field')
end

---@private
---@param action_type string
---@param filter? string
function M.run_code_action(action_type, filter)
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

return M
