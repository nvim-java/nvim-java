local log = require('java-core.utils.log2')
local class = require('java-core.utils.class')
local await = require('async.waits.wait_with_error_handler')

---@alias java-core.JdtlsRequestMethod
---| 'workspace/executeCommand'
---| 'java/inferSelection'
---| 'java/getRefactorEdit'
---| 'java/buildWorkspace'
---| 'java/checkConstructorsStatus'
---| 'java/generateConstructors'
---| 'java/checkToStringStatus'
---| 'java/generateToString'
---| 'java/checkHashCodeEqualsStatus'
---| 'java/generateHashCodeEquals'
---| 'java/checkDelegateMethodsStatus'
---| 'java/generateDelegateMethods'
---| 'java/move'
---| 'java/searchSymbols'
---| 'java/getMoveDestinations'
---| 'java/listOverridableMethods'
---| 'java/addOverridableMethods'

---@alias jdtls.CodeActionCommand
---| 'extractVariable'
---| 'assignVariable'
---| 'extractVariableAllOccurrence'
---| 'extractConstant'
---| 'extractMethod'
---| 'extractField'
---| 'extractInterface'
---| 'changeSignature'
---| 'assignField'
---| 'convertVariableToField'
---| 'invertVariable'
---| 'introduceParameter'
---| 'convertAnonymousClassToNestedCommand'

---@class jdtls.RefactorWorkspaceEdit
---@field edit lsp.WorkspaceEdit
---@field command? lsp.Command
---@field errorMessage? string

---@class jdtls.SelectionInfo
---@field name string
---@field length number
---@field offset number
---@field params? string[]

---@class java-core.JdtlsClient
---@field client vim.lsp.Client
local JdtlsClient = class()

function JdtlsClient:_init(client)
	self.client = client
end

---Sends a LSP request
---@param method java-core.JdtlsRequestMethod
---@param params table
---@param buffer? number
function JdtlsClient:request(method, params, buffer)
	log.debug('sending LSP request: ' .. method)

	return await(function(callback)
		local on_response = function(err, result)
			if err then
				log.error(method .. ' failed! arguments: ', params, ' error: ', err)
			else
				log.debug(method .. ' success! response: ', result)
			end

			callback(err, result)
		end

		---@diagnostic disable-next-line: param-type-mismatch
		return self.client:request(method, params, on_response, buffer)
	end)
end

--- Sends a notification to an LSP server.
---
--- @param method vim.lsp.protocol.Method.ClientToServer.Notification LSP method name.
--- @param params table? LSP request params.
--- @return boolean status indicating if the notification was successful.
---                        If it is false, then the client has shutdown.
function JdtlsClient:notify(method, params)
	log.debug('sending LSP notify: ' .. method)
	return self.client:notify(method, params)
end

---Executes a workspace/executeCommand and returns the result
---@param command string workspace command to execute
---@param arguments? lsp.LSPAny[]
---@param buffer? integer
---@return lsp.LSPAny
function JdtlsClient:workspace_execute_command(command, params, buffer)
	return self:request('workspace/executeCommand', {
		command = command,
		arguments = params,
	}, buffer)
end

---@class jdtls.ResourceMoveDestination
---@field displayName string
---@field isDefaultPackage boolean
---@field isParentOfSelectedFile boolean
---@field path string
---@field project string
---@field uri string

---@class jdtls.InstanceMethodMoveDestination
---@field bindingKey string
---@field isField boolean
---@field isSelected boolean
---@field name string
---@field type string

---@class jdtls.listOverridableMethodsResponse
---@field methods jdtls.OverridableMethod[]
---@field type string

---@class jdtls.OverridableMethod
---@field key string
---@field bindingKey string
---@field declaringClass string
---@field declaringClassType string
---@field name string
---@field parameters string[]
---@field unimplemented boolean

---@class jdtls.MoveDestinationsResponse
---@field errorMessage? string
---@field destinations  jdtls.InstanceMethodMoveDestination[]|jdtls.ResourceMoveDestination[]

---@class jdtls.ImportCandidate
---@field fullyQualifiedName string
---@field id string

---@class jdtls.ImportSelection
---@field candidates jdtls.ImportCandidate[]
---@field range Range

---@param params jdtls.MoveParams
---@return jdtls.MoveDestinationsResponse
function JdtlsClient:get_move_destination(params)
	return self:request('java/getMoveDestinations', params)
end

---@class jdtls.MoveParams
---@field moveKind string
---@field sourceUris string[]
---@field params lsp.CodeActionParams | nil
---@field destination? any
---@field updateReferences? boolean

---@param params jdtls.MoveParams
---@return jdtls.RefactorWorkspaceEdit
function JdtlsClient:java_move(params)
	return self:request('java/move', params)
end

---@class jdtls.SearchSymbolParams: lsp.WorkspaceSymbolParams
---@field projectName string
---@field maxResults? number
---@field sourceOnly? boolean

---@param params jdtls.SearchSymbolParams
---@return lsp.SymbolInformation
function JdtlsClient:java_search_symbols(params)
	return self:request('java/searchSymbols', params)
end

---Returns more information about the object the cursor is on
---@param command jdtls.CodeActionCommand
---@param params lsp.CodeActionParams
---@param buffer? number
---@return jdtls.SelectionInfo[]
function JdtlsClient:java_infer_selection(command, params, buffer)
	return self:request('java/inferSelection', {
		command = command,
		context = params,
	}, buffer)
end

--- @class jdtls.VariableBinding
--- @field bindingKey string
--- @field name string
--- @field type string
--- @field isField boolean
--- @field isSelected? boolean

---@class jdtls.MethodBinding
---@field bindingKey string;
---@field name string;
---@field parameters string[];

---@class jdtls.JavaCheckConstructorsStatusResponse
---@field constructors jdtls.MethodBinding
---@field fields jdtls.MethodBinding

---@param params lsp.CodeActionParams
---@return jdtls.JavaCheckConstructorsStatusResponse
function JdtlsClient:java_check_constructors_status(params)
	return self:request('java/checkConstructorsStatus', params)
end

---@param params jdtls.GenerateConstructorsParams
---@return lsp.WorkspaceEdit
function JdtlsClient:java_generate_constructor(params)
	return self:request('java/generateConstructors', params)
end

---@class jdtls.CheckToStringResponse
---@field type string
---@field fields jdtls.VariableBinding[]
---@field exists boolean

---@param params lsp.CodeActionParams
---@return jdtls.CheckToStringResponse
function JdtlsClient:java_check_to_string_status(params)
	return self:request('java/checkToStringStatus', params)
end

---@class jdtls.GenerateToStringParams
---@field context lsp.CodeActionParams
---@field fields jdtls.VariableBinding[]

---@param params jdtls.GenerateToStringParams
---@return lsp.WorkspaceEdit
function JdtlsClient:java_generate_to_string(params)
	return self:request('java/generateToString', params)
end

---@class jdtls.CheckHashCodeEqualsResponse
---@field type string
---@field fields jdtls.VariableBinding[]
---@field existingMethods string[]

---@param params lsp.CodeActionParams
---@return jdtls.CheckHashCodeEqualsResponse
function JdtlsClient:java_check_hash_code_equals_status(params)
	return self:request('java/checkHashCodeEqualsStatus', params)
end

---@class jdtls.GenerateHashCodeEqualsParams
---@field context lsp.CodeActionParams
---@field fields jdtls.VariableBinding[]
---@field regenerate boolean

---@param params jdtls.GenerateHashCodeEqualsParams
---@return lsp.WorkspaceEdit
function JdtlsClient:java_generate_hash_code_equals(params)
	return self:request('java/generateHashCodeEquals', params)
end

---@class jdtls.DelegateField
---@field field jdtls.VariableBinding
---@field delegateMethods jdtls.MethodBinding[]

---@class jdtls.CheckDelegateMethodsResponse
---@field delegateFields jdtls.DelegateField[]

---@param params lsp.CodeActionParams
---@return jdtls.CheckDelegateMethodsResponse
function JdtlsClient:java_check_delegate_methods_status(params)
	return self:request('java/checkDelegateMethodsStatus', params)
end

---@class jdtls.DelegateEntry
---@field field jdtls.VariableBinding
---@field delegateMethod jdtls.MethodBinding

---@class jdtls.GenerateDelegateMethodsParams
---@field context lsp.CodeActionParams
---@field delegateEntries jdtls.DelegateEntry[]

---@param params jdtls.GenerateDelegateMethodsParams
---@return lsp.WorkspaceEdit
function JdtlsClient:java_generate_delegate_methods(params)
	return self:request('java/generateDelegateMethods', params)
end

---@class jdtls.GenerateConstructorsParams
---@field context lsp.CodeActionParams
---@field constructors jdtls.MethodBinding[]
---@field fields jdtls.VariableBinding[]

---Returns refactor details
---@param command jdtls.CodeActionCommand
---@param action_params lsp.CodeActionParams
---@param formatting_options lsp.FormattingOptions
---@param selection_info jdtls.SelectionInfo[];
---@param buffer? number
---@return jdtls.RefactorWorkspaceEdit
function JdtlsClient:java_get_refactor_edit(command, action_params, formatting_options, selection_info, buffer)
	local params = {
		command = command,
		context = action_params,
		options = formatting_options,
		commandArguments = selection_info,
	}

	return self:request('java/getRefactorEdit', params, buffer)
end

---Returns a list of methods that can be overridden
---@param params lsp.CodeActionParams
---@param buffer? number
---@return jdtls.listOverridableMethodsResponse
function JdtlsClient:list_overridable_methods(params, buffer)
	return self:request('java/listOverridableMethods', params, buffer)
end

---Returns a list of methods that can be overridden
---@param context lsp.CodeActionParams
---@param overridable_methods jdtls.OverridableMethod[]
---@param buffer? number
---@return lsp.WorkspaceEdit
function JdtlsClient:add_overridable_methods(context, overridable_methods, buffer)
	return self:request('java/addOverridableMethods', {
		context = context,
		overridableMethods = overridable_methods,
	}, buffer)
end

---Compile the workspace
---@param is_full_compile boolean if true, a complete full compile of the
---workspace will be executed
---@param buffer number
---@return java-core.CompileWorkspaceStatus
function JdtlsClient:java_build_workspace(is_full_compile, buffer)
	---@diagnostic disable-next-line: param-type-mismatch
	return self:request('java/buildWorkspace', is_full_compile, buffer)
end

---Returns the decompiled class file content
---@param uri string uri of the class file
---@return string # decompiled file content
function JdtlsClient:java_decompile(uri)
	---@type string
	return self:workspace_execute_command('java.decompile', { uri })
end

function JdtlsClient:get_capability(...)
	local capability = self.client.server_capabilities

	for _, value in ipairs({ ... }) do
		if type(capability) ~= 'table' then
			log.fmt_warn('Looking for capability: %s in value %s', value, capability)
			return nil
		end

		capability = capability[value]
	end

	return capability
end

---Updates JDTLS settings via workspace/didChangeConfiguration
---@param settings JavaConfigurationSettings
---@return boolean
function JdtlsClient:workspace_did_change_configuration(settings)
	local params = { settings = settings }
	return self:notify('workspace/didChangeConfiguration', params)
end

---Returns true if the LS supports the given command
---@param command_name string name of the command
---@return boolean # true if the command is supported
function JdtlsClient:has_command(command_name)
	local commands = self:get_capability('executeCommandProvider', 'commands')

	if not commands then
		return false
	end

	return vim.tbl_contains(commands, command_name)
end

return JdtlsClient
