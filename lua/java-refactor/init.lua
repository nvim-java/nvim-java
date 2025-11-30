local event = require('java-core.utils.event')
local cmd_util = require('java-core.utils.command')

local M = {}

local group = vim.api.nvim_create_augroup('java-refactor-command-register', {})

M.setup = function()
	event.on_jdtls_attach({
		group = group,
		once = true,
		callback = function()
			M.reg_client_commands()
			M.reg_refactor_commands()
			M.reg_build_commands()
		end,
	})
end

M.reg_client_commands = function()
	local code_action_handlers = require('java-refactor.client-command-handlers')

	for key, handler in pairs(code_action_handlers) do
		vim.lsp.commands[key] = handler
	end
end

M.reg_refactor_commands = function()
	local java = require('java')
	local code_action_api = require('java-refactor.api.refactor')

	for api_name, api in pairs(code_action_api) do
		cmd_util.register_api(java, { 'refactor', api_name }, api, { range = 2 })
	end
end

M.reg_build_commands = function()
	local java = require('java')
	local code_action_api = require('java-refactor.api.build')

	for api_name, api in pairs(code_action_api) do
		cmd_util.register_api(java, { 'build', api_name }, api, {})
	end
end

return M
