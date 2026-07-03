local assert = require('luassert')

describe('LSP utils', function()
	local path = require('java-core.utils.path')

	it('uses a stable jdtls-root specific config cache path', function()
		local lsp = require('java-core.utils.lsp')
		local cache_root = path.join(vim.fn.stdpath('cache'), 'jdtls')
		local jdtls_root = '/nix/store/example-jdtls/share/java/jdtls'

		local conf_path = lsp.get_jdtls_cache_conf_path(jdtls_root)

		assert.equals(path.join(cache_root, 'config_' .. vim.fn.sha256(jdtls_root)), conf_path)
	end)

	it('keeps the legacy config cache path when no jdtls root is provided', function()
		local lsp = require('java-core.utils.lsp')

		local conf_path = lsp.get_jdtls_cache_conf_path()

		assert.equals(path.join(vim.fn.stdpath('cache'), 'jdtls', 'config'), conf_path)
	end)
end)
