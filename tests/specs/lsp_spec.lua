local lsp_utils = dofile('tests/utils/lsp-utils.lua')
local assert = require('luassert')
local system = require('java-core.utils.system')

describe('LSP Attach', function()
	it('should attach when opening a Java buffer', function()
		vim.cmd.edit('HelloWorld.java')

		local jdtls = lsp_utils.wait_for_lsp_attach('jdtls', 30000)
		local spring = lsp_utils.wait_for_lsp_attach('spring-boot', 30000)

		if system.get_os() == 'win' then
			vim.fn.readfile('C:/Users/runneradmin/AppData/Local/nvim-data/lsp.log')
		end
		assert.is_not_nil(jdtls, 'JDTLS should attach to Java buffer')
		assert.is_not_nil(spring, 'Spring Boot should attach to Java buffer')
	end)
end)
