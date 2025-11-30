local class = require('java-core.utils.class')
local notify = require('java-core.utils.notify')
local JdtlsClient = require('java-core.ls.clients.jdtls-client')
local List = require('java-core.utils.list')
local ui = require('java.ui.utils')

local refactor_edit_request_needed_actions = {
	'convertVariableToField',
	'extractConstant',
	'extractField',
	'extractMethod',
	'extractVariable',
	'extractVariableAllOccurrence',
}

local available_actions = List:new({
	'assignField',
	'assignVariable',
	'convertAnonymousClassToNestedCommand',
	'introduceParameter',
	'invertVariable',
	-- 'moveFile',
	'moveInstanceMethod',
	'moveStaticMember',
	'moveType',
	-- 'changeSignature',
	-- 'extractInterface',
}):concat(refactor_edit_request_needed_actions)

---@class java-refactor.Refactor
---@field jdtls_client java-core.JdtlsClient
local Refactor = class()

---@param client vim.lsp.Client
function Refactor:_init(client)
	self.jdtls_client = JdtlsClient(client)
end

---Run refactor command
---@param action_name jdtls.CodeActionCommand
---@param action_context lsp.CodeActionParams
---@param action_info lsp.LSPAny
function Refactor:refactor(action_name, action_context, action_info)
	if not vim.tbl_contains(available_actions, action_name) then
		notify.error(string.format('Refactoring command "%s" is not supported', action_name))
		return
	end

	if vim.tbl_contains(refactor_edit_request_needed_actions, action_name) then
		local formatting_options = self:make_formatting_options()
		local selections

		if vim.tbl_contains(refactor_edit_request_needed_actions, action_name) then
			selections = self:get_selections(action_name, action_context)
		end

		local changes = self.jdtls_client:java_get_refactor_edit(
			action_name,
			action_context,
			formatting_options,
			selections,
			vim.api.nvim_get_current_buf()
		)

		self:perform_refactor_edit(changes)
	elseif action_name == 'moveFile' then
		self:move_file(action_info --[[@as jdtls.CodeActionMoveTypeCommandInfo]])
	elseif action_name == 'moveType' then
		self:move_type(action_context, action_info --[[@as jdtls.CodeActionMoveTypeCommandInfo]])
	elseif action_name == 'moveStaticMember' then
		self:move_static_member(action_context, action_info --[[@as jdtls.CodeActionMoveTypeCommandInfo]])
	elseif action_name == 'moveInstanceMethod' then
		self:move_instance_method(action_context, action_info --[[@as jdtls.CodeActionMoveTypeCommandInfo]])
	end
end

---@private
---@param action_info jdtls.CodeActionMoveTypeCommandInfo
function Refactor:move_file(action_info)
	if not action_info or not action_info.uri then
		return
	end

	local move_des = self.jdtls_client:get_move_destination({
		moveKind = 'moveResource',
		sourceUris = { action_info.uri },
		params = nil,
	})

	if not move_des or not move_des.destinations or #move_des.destinations < 1 then
		notify.error('Cannot find available Java packages to move the selected files to.')
		return
	end

	---@type jdtls.ResourceMoveDestination[]
	local destinations = move_des.destinations

	local selected_destination = ui.select('Choose the target package', destinations, function(destination)
		return destination.displayName .. ' ' .. destination.path
	end)

	if not selected_destination then
		return
	end

	local changes = self.jdtls_client:java_move({
		moveKind = 'moveResource',
		sourceUris = { action_info.uri },
		params = nil,
		destination = selected_destination,
	})

	self:perform_refactor_edit(changes)
end

---@private
---@param action_context lsp.CodeActionParams
---@param action_info jdtls.CodeActionMoveTypeCommandInfo
function Refactor:move_instance_method(action_context, action_info)
	local move_des = self.jdtls_client:get_move_destination({
		moveKind = 'moveInstanceMethod',
		sourceUris = { action_context.textDocument.uri },
		params = action_context,
	})

	if move_des and move_des.errorMessage then
		notify.error(move_des.errorMessage)
		return
	end

	if not move_des or not move_des.destinations or #move_des.destinations < 1 then
		notify.error('Cannot find possible class targets to move the selected method to.')
		return
	end

	---@type jdtls.InstanceMethodMoveDestination[]
	local destinations = move_des.destinations

	local method_name = action_info and action_info.displayName or ''

	local selected_destination = ui.select(
		string.format('Select the new class for the instance method %s', method_name),
		destinations,
		function(destination)
			return destination.type .. ' ' .. destination.name
		end,
		{ prompt_single = true }
	)

	if not selected_destination then
		return
	end

	self:perform_move('moveInstanceMethod', action_context, selected_destination)
end

---@private
---@param action_context lsp.CodeActionParams
---@param action_info jdtls.CodeActionMoveTypeCommandInfo
function Refactor:move_static_member(action_context, action_info)
	local exclude = List:new()

	if action_info.enclosingTypeName then
		exclude:push(action_info.enclosingTypeName)
		if action_info.memberType == 55 or action_info.memberType == 71 or action_info.memberType == 81 then
			exclude:push(action_info.enclosingTypeName .. '.' .. action_info.displayName)
		end
	end

	local project_name = action_info and action_info.projectName or nil
	local member_name = action_info and action_info.displayName and action_info.displayName or ''

	local selected_class = self:select_target_class(
		string.format('Select the new class for the static member %s.', member_name),
		project_name,
		exclude
	)

	if not selected_class then
		return
	end

	self:perform_move('moveStaticMember', action_context, selected_class)
end

---@private
---@param action_context lsp.CodeActionParams
---@param action_info jdtls.CodeActionMoveTypeCommandInfo
function Refactor:move_type(action_context, action_info)
	if not action_info or not action_info.supportedDestinationKinds then
		return
	end

	local selected_destination_kind = ui.select(
		'What would you like to do?',
		action_info.supportedDestinationKinds,
		function(kind)
			if kind == 'newFile' then
				return string.format('Move type "%s" to new file', action_info.displayName)
			else
				return string.format('Move type "%s" to another class', action_info.displayName)
			end
		end
	)

	if not selected_destination_kind then
		return
	end

	if selected_destination_kind == 'newFile' then
		self:perform_move('moveTypeToNewFile', action_context)
	else
		local exclude = List:new()

		if action_info.enclosingTypeName then
			exclude:push(action_info.enclosingTypeName)
			exclude:push(action_info.enclosingTypeName .. ':' .. action_info.displayName)
		end

		local selected_class = self:select_target_class(
			string.format('Select the new class for the type %s.', action_info.displayName),
			action_info.projectName,
			exclude
		)

		if not selected_class then
			return
		end

		self:perform_move('moveStaticMember', action_context, selected_class)
	end
end

---@private
---@param move_kind string
---@param action_context lsp.CodeActionParams
---@param destination? jdtls.InstanceMethodMoveDestination | jdtls.ResourceMoveDestination | lsp.SymbolInformation
function Refactor:perform_move(move_kind, action_context, destination)
	local changes = self.jdtls_client:java_move({
		moveKind = move_kind,
		sourceUris = { action_context.textDocument.uri },
		params = action_context,
		destination = destination,
	})

	self:perform_refactor_edit(changes)
end

---@private
---@param changes jdtls.RefactorWorkspaceEdit
function Refactor:perform_refactor_edit(changes)
	if not changes then
		notify.warn('No edits suggested for the code action')
		return
	end

	if changes.errorMessage then
		notify.error(changes.errorMessage)
		return
	end
	vim.lsp.util.apply_workspace_edit(changes.edit, 'utf-8')

	if changes.command then
		self:run_lsp_client_command(changes.command.command, changes.command.arguments)
	end
end

---@private
---@param prompt string
---@param project_name string
---@param exclude string[]
function Refactor:select_target_class(prompt, project_name, exclude)
	local classes = self.jdtls_client:java_search_symbols({
		query = '*',
		projectName = project_name,
		sourceOnly = true,
	})

	---@type lsp.SymbolInformation[]
	local filtered_classes = List:new(classes):filter(function(cls)
		local type_name = cls.containerName .. '.' .. cls.name
		return not vim.tbl_contains(exclude, type_name)
	end)

	local selected = ui.select(prompt, filtered_classes, function(cls)
		return cls.containerName .. '.' .. cls.name
	end)

	return selected
end

---@private
---@param command_name string
---@param arguments any
function Refactor:run_lsp_client_command(command_name, arguments)
	local command = vim.lsp.commands[command_name]

	if not command then
		notify.error('Command "' .. command_name .. '" is not supported')
		return
	end

	command(arguments)
end

---@private
---@return lsp.FormattingOptions
function Refactor:make_formatting_options()
	return {
		tabSize = vim.bo.tabstop,
		insertSpaces = vim.bo.expandtab,
	}
end

---@private
---@param refactor_type jdtls.CodeActionCommand
---@param params lsp.CodeActionParams
---@return jdtls.SelectionInfo[]
function Refactor:get_selections(refactor_type, params)
	local selections = List:new()
	local buffer = vim.api.nvim_get_current_buf()

	if
		params.range.start.character == params.range['end'].character
		and params.range.start.line == params.range['end'].line
	then
		local selection_res = self.jdtls_client:java_infer_selection(refactor_type, params, buffer)

		if not selection_res then
			return selections
		end

		local selection = selection_res[1]

		if selection.params and vim.islist(selection.params) then
			local initialize_in = ui.select('Initialize the field in', selection.params)

			if not initialize_in then
				return selections
			end

			selections:push(initialize_in)
		end

		selections:push(selection)
	end

	return selections
end

---@class jdtls.CodeActionMoveTypeCommandInfo
---@field displayName string
---@field enclosingTypeName string
---@field memberType number
---@field projectName string
---@field supportedDestinationKinds string[]
---@field uri? string

return Refactor
