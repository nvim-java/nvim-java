local lsp_utils = dofile('tests/utils/lsp-utils.lua')
local system = require('java-core.utils.system')
local assert = require('luassert')

describe('LSP Attach', function()
	it('should attach when opening a Java buffer', function()
		if system.get_os() == 'mac' then
			vim.print(vim.fn.readfile('/Users/runner/.local/state/nvim/lsp.log'))
		end

		vim.cmd.edit('HelloWorld.java')

		local jdtls = lsp_utils.wait_for_lsp_attach('jdtls', 30000)
		local spring = lsp_utils.wait_for_lsp_attach('spring-boot', 30000)

		assert.is_not_nil(jdtls, 'JDTLS should attach to Java buffer')
		assert.is_not_nil(spring, 'Spring Boot should attach to Java buffer')
	end)
end)
