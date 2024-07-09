local lspconfig = require('lspconfig')
local log = require('java.utils.log')
local mason_util = require('java-core.utils.mason')

local server = require('java-core.ls.servers.jdtls')

local M = {}

---comment
---@param config java.Config
function M.setup(config)
	log.info('wrap lspconfig.java.setup function to inject a custom java config')
	---@type fun(config: LspSetupConfig)
	local org_setup = lspconfig.jdtls.setup

	lspconfig.jdtls.setup = function(user_config)
		vim.api.nvim_exec_autocmds('User', { pattern = 'JavaJdtlsSetup' })

		local jdtls_plugins = {}

		if config.java_test.enable then
			table.insert(jdtls_plugins, 'java-test')
		end

		if config.java_debug_adapter.enable then
			table.insert(jdtls_plugins, 'java-debug-adapter')
		end

		if config.spring_boot_tools.enable then
			table.insert(jdtls_plugins, 'spring-boot-tools')
		end

		local default_config = server.get_config({
			root_markers = config.root_markers,
			jdtls_plugins = jdtls_plugins,
			use_mason_jdk = config.jdk.auto_install,
		})

		if config.spring_boot_tools.enable then
			require('spring_boot').setup({
				ls_path = mason_util.get_pkg_path('spring-boot-tools')
					.. '/extension/language-server',
			})

			require('spring_boot').init_lsp_commands()
		end

		org_setup(vim.tbl_extend('force', default_config, user_config))
	end
end

return M
