---@param client_command jdtls.ClientCommand
local function run_client_command(client_command, ...)
	local handlers = require('java-refactor.client-command-handlers')
	handlers[client_command](...)
end

local M = {
	build_workspace = function()
		local ClientCommand = require('java-refactor.client-command')
		run_client_command(ClientCommand.COMPILE_WORKSPACE, true)
	end,

	clean_workspace = function()
		local ClientCommand = require('java-refactor.client-command')
		run_client_command(ClientCommand.CLEAN_WORKSPACE)
	end,
}

return M
