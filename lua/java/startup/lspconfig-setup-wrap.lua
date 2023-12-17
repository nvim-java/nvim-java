local lspconfig = require('lspconfig')
local log = require('java.utils.log')

local server = require('java-core.ls.servers.jdtls')

local M = {}

---comment
---@param config java.Config
function M.setup(config)
	log.info('wrap lspconfig.java.setup function to inject a custom java config')
	---@type fun(config: LspSetupConfig)
	local org_setup = lspconfig.jdtls.setup

	lspconfig.jdtls.setup = function(user_config)
		local jdtls_plugins = {}

		if config.java_test.enable then
			table.insert(jdtls_plugins, 'java-test')
		end

		if config.java_debug_adapter.enable then
			table.insert(jdtls_plugins, 'java-debug-adapter')
		end

		local default_config = server.get_config({
			root_markers = config.root_markers,
			jdtls_plugins = jdtls_plugins,
			use_mason_jdk = config.jdk.auto_install,
		})

		org_setup(vim.tbl_extend('force', default_config, user_config))
	end
end

return M
