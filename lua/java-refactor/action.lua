local ui = require('java.ui.utils')
local class = require('java-core.utils.class')
local JdtlsClient = require('java-core.ls.clients.jdtls-client')
local RefactorCommands = require('java-refactor.refactor')
local notify = require('java-core.utils.notify')
local List = require('java-core.utils.list')
local lsp_utils = require('java-core.utils.lsp')

---@class java-refactor.Action
---@field client vim.lsp.Client
---@field jdtls java-core.JdtlsClient
local Action = class()

---@param client vim.lsp.Client
function Action:_init(client)
	self.client = client
	self.jdtls = JdtlsClient(client)
	self.refactor = RefactorCommands(client)
end

---@class java-refactor.RenameAction
---@field length number
---@field offset number
---@field uri string

---@param params java-refactor.RenameAction[]
function Action:rename(params)
	for _, rename in ipairs(params) do
		local buffer = vim.uri_to_bufnr(rename.uri)

		local line

		vim.api.nvim_buf_call(buffer, function()
			line = vim.fn.byte2line(rename.offset)
		end)

		local start_char = rename.offset - vim.fn.line2byte(line) + 1

		vim.api.nvim_win_set_cursor(0, { line, start_char })

		vim.lsp.buf.rename(nil, {
			name = 'jdtls',
			bufnr = buffer,
		})
	end
end

---@param params nvim.CodeActionParamsResponse
function Action:generate_constructor(params)
	local status = self.jdtls:java_check_constructors_status(params.params)

	if not status or not status.constructors then
		return
	end

	local selected_constructor = ui.select(
		'Select super class constructor(s).',
		status.constructors,
		function(constructor)
			return string.format('%s %s', constructor.name, table.concat(constructor.parameters, ', '))
		end
	)

	if not selected_constructor then
		return
	end

	local selected_fields = ui.multi_select('Select Fields:', status.fields, function(field)
		return field.name
	end)

	local edit = self.jdtls:java_generate_constructor({
		context = params.params,
		constructors = { selected_constructor },
		fields = selected_fields or {},
	})

	vim.lsp.util.apply_workspace_edit(edit, 'utf-8')
end

---@param params nvim.CodeActionParamsResponse
function Action:generate_to_string(params)
	local status = self.jdtls:java_check_to_string_status(params.params)

	if status.exists then
		local prompt = string.format(
			'Method "toString()" already exists in the Class %s. Do you want to replace the implementation?',
			status.type
		)
		local choice = ui.select(prompt, { 'Replace', 'Cancel' })

		if choice ~= 'Replace' then
			return
		end
	end

	local fields = ui.multi_select(
		'Select the fields to include in the toString() method.',
		status.fields,
		function(field)
			return field.name
		end
	)

	if not fields then
		return
	end

	local edit = self.jdtls:java_generate_to_string({
		context = params.params,
		fields = fields,
	})

	vim.lsp.util.apply_workspace_edit(edit, 'utf-8')
end

---@param params nvim.CodeActionParamsResponse
function Action:generate_hash_code_and_equals(params)
	local status = self.jdtls:java_check_hash_code_equals_status(params.params)

	if not status or not status.fields or #status.fields < 1 then
		local message = string.format('The operation is not applicable to the type %s.', status.type)
		notify.warn(message)
		return
	end

	local regenerate = false

	if status.existingMethods and #status.existingMethods > 0 then
		local prompt = string.format(
			'Methods %s already exists in the Class %s. Do you want to regenerate the implementation?',
			'Regenerate',
			'Cancel'
		)

		local choice = ui.select(prompt, { 'Regenerate', 'Cancel' })

		if choice == 'Regenerate' then
			regenerate = true
		end
	end

	local fields = ui.multi_select(
		'Select the fields to include in the hashCode() and equals() methods.',
		status.fields,
		function(field)
			return field.name
		end
	)

	if not fields or #fields < 1 then
		return
	end

	local edit = self.jdtls:java_generate_hash_code_equals({
		context = params.params,
		fields = fields,
		regenerate = regenerate,
	})

	vim.lsp.util.apply_workspace_edit(edit, 'utf-8')
end

---@param params nvim.CodeActionParamsResponse
function Action:generate_delegate_methods_prompt(params)
	local status = self.jdtls:java_check_delegate_methods_status(params.params)

	if not status or not status.delegateFields or #status.delegateFields < 1 then
		notify.warn('All delegatable methods are already implemented.')
		return
	end

	local selected_delegate_field = ui.select(
		'Select target to generate delegates for.',
		status.delegateFields,
		function(field)
			return field.field.name .. ': ' .. field.field.type
		end
	)

	if not selected_delegate_field then
		return
	end

	if #selected_delegate_field.delegateMethods < 1 then
		notify.warn('All delegatable methods are already implemented.')
		return
	end

	local selected_delegate_methods = ui.multi_select(
		'Select methods to generate delegates for.',
		selected_delegate_field.delegateMethods,
		function(method)
			return string.format(
				'%s.%s(%s)',
				selected_delegate_field.field.name,
				method.name,
				table.concat(method.parameters, ', ')
			)
		end
	)

	if not selected_delegate_methods or #selected_delegate_methods < 1 then
		return
	end

	local delegate_entries = List:new(selected_delegate_methods):map(
		---@param method jdtls.MethodBinding
		function(method)
			return {
				field = selected_delegate_field.field,
				delegateMethod = method,
			}
		end
	)

	local edit = self.jdtls:java_generate_delegate_methods({
		context = params.params,
		delegateEntries = delegate_entries,
	})

	vim.lsp.util.apply_workspace_edit(edit, 'utf-8')
end

---@param command lsp.Command
function Action:apply_refactoring_command(command)
	local action_name = command.arguments[1] --[[@as jdtls.CodeActionCommand]]
	local action_context = command.arguments[2] --[[@as lsp.CodeActionParams]]
	local action_info = command.arguments[3] --[[@as lsp.LSPAny]]

	self.refactor:refactor(action_name, action_context, action_info)
end

---comment
---@param is_full_compile boolean
---@return java-core.CompileWorkspaceStatus
function Action:build_workspace(is_full_compile)
	return self.jdtls:java_build_workspace(is_full_compile, 0)
end

function Action:clean_workspace()
	local client = lsp_utils.get_jdtls()
	local data_path = lsp_utils.get_jdtls_cache_data_path(client.root_dir)

	local prompt = string.format('Do you want to delete "%s"', data_path)

	local choice = ui.select(prompt, { 'Yes', 'No' })

	if choice ~= 'Yes' then
		return
	end

	return vim.fn.delete(data_path, 'rf')
end

---@class java-refactor.ApplyRefactoringCommandParams
---@field bufnr number
---@field client_id number
---@field method string
---@field params lsp.CodeActionParams
---@field version number

---@param params nvim.CodeActionParamsResponse
function Action:override_methods_prompt(params)
	local status = self.jdtls:list_overridable_methods(params.params)

	if not status or not status.methods or #status.methods < 1 then
		notify.warn('No methods to override.')
		return
	end

	local selected_methods = ui.multi_select('Select methods to override.', status.methods, function(method)
		return string.format('%s(%s)', method.name, table.concat(method.parameters, ', '))
	end)

	if not selected_methods or #selected_methods < 1 then
		return
	end

	local edit = self.jdtls:add_overridable_methods(params.params, selected_methods)
	vim.lsp.util.apply_workspace_edit(edit, 'utf-8')
end

---@param selections jdtls.ImportSelection[]
function Action:choose_imports(selections)
	local selected_candidates = {}

	for _, selection in ipairs(selections) do
		local selected_candidate = ui.select_sync(
			'Select methods to override.',
			selection.candidates,
			function(candidate, index)
				return index .. ' ' .. candidate.fullyQualifiedName
			end
		)

		table.insert(selected_candidates, selected_candidate)
	end

	return selected_candidates
end

return Action
