local lspconfig = require('lspconfig')

local M = {}

lspconfig.util.on_setup = lspconfig.util.add_hook_before(
	lspconfig.util.on_setup,
	function(config)
		if config.name == 'jdtls' then
			vim.g.nvim_java_jdtls_setup_is_called = true
		end
	end
)

local message = 'Looks like require("lspconfig").jdtls.setup() is called before require("java").setup().'
	.. '\nnvim-java will continue to setup but most features may not work as expected'
	.. '\nThis might be due to old installation instructions.'
	.. '\nPlease check the latest guide at https://github.com/nvim-java/nvim-java#hammer-how-to-install'
	.. '\nIf you know what you are doing, you can disable the check from the config'
	.. '\nhttps://github.com/nvim-java/nvim-java#wrench-configuration'

function M.is_valid()
	if vim.g.nvim_java_jdtls_setup_is_called then
		return {
			success = false,
			continue = true,
			message = message,
		}
	end

	local clients = vim.lsp.get_clients
			and vim.lsp.get_clients({ name = 'jdtls' })
		or vim.lsp.get_active_clients({ name = 'jdtls' })

	if #clients > 0 then
		return {
			success = false,
			continue = true,
			message = message,
		}
	end

	return {
		success = true,
		continue = true,
	}
end

return M
