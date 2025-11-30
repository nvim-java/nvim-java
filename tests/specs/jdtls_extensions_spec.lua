local lsp_utils = dofile('tests/utils/lsp-utils.lua')
local assert = require('luassert')

describe('JDTLS Extensions', function()
	it('should bundle java-test, java-debug, and spring-boot-tools extensions', function()
		vim.cmd.edit('HelloWorld.java')

		local client = lsp_utils.wait_for_lsp_attach('jdtls', 30000)
		local bundles = client.config.init_options.bundles

		assert.is_not_nil(bundles, 'Bundles should be configured')
		assert.is_true(#bundles > 0, 'Bundles should not be empty')

		local has_java_test = false
		local has_java_debug = false
		local has_spring_boot = false

		for _, bundle in ipairs(bundles) do
			if bundle:match('java%-test') and bundle:match('com%.microsoft%.java%.test%.plugin') then
				has_java_test = true
			end
			if bundle:match('java%-debug') and bundle:match('com%.microsoft%.java%.debug%.plugin') then
				has_java_debug = true
			end
			if bundle:match('spring%-boot%-tools') and bundle:match('jdt%-ls%-extension%.jar') then
				has_spring_boot = true
			end
		end

		assert.is_true(has_java_test, 'java-test extension (com.microsoft.java.test.plugin) should be bundled')
		assert.is_true(has_java_debug, 'java-debug extension (com.microsoft.java.debug.plugin) should be bundled')
		assert.is_true(has_spring_boot, 'spring-boot-tools extension (jdt-ls-extension.jar) should be bundled')
	end)
end)
