local log = require('java-core.utils.log')
local lspconfig = require('lspconfig')
local server = require('java-core.server')

local M = {}

function M.wrap_lspconfig_setup()
	log.info('wrap lspconfig.java.setup function to inject a custom java config')
	---@type fun(config: LSPSetupConfig)
	local org_setup = lspconfig.jdtls.setup

	lspconfig.jdtls.setup = function(user_config)
		local config = server.get_config({
			root_markers = {
				'settings.gradle',
				'settings.gradle.kts',
				'pom.xml',
				'build.gradle',
				'mvnw',
				'gradlew',
				'build.gradle',
				'build.gradle.kts',
				'.git',
			},
		})

		config = vim.tbl_deep_extend('force', user_config, config)

		org_setup(config)
	end
end

return M
