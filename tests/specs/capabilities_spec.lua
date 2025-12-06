local lsp_utils = dofile('tests/utils/lsp-utils.lua')
local capabilities = dofile('tests/constants/capabilities.lua')
local List = require('java-core.utils.list')
local assert = require('luassert')
local err = require('java-core.utils.errors')

describe('LSP Capabilities', function()
	it('should have all required commands', function()
		vim.cmd.edit('HelloWorld.java')

		local client = lsp_utils.wait_for_lsp_attach('jdtls', 30000)
		local commands = client.server_capabilities.executeCommandProvider.commands
		local actual_cmds = List:new(commands)

		for _, required_cmd in ipairs(capabilities.required_cmds) do
			assert.is_true(actual_cmds:contains(required_cmd), 'Missing required command: ' .. required_cmd)
		end

		local extra_cmds = actual_cmds:filter(function(cmd)
			return not capabilities.required_cmds:contains(cmd)
		end)

		if #extra_cmds > 0 then
			err.throw('Additional commands found that are not in required list:', extra_cmds)
		end
	end)
end)
