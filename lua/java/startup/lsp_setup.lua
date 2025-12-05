local path = require('java-core.utils.path')
local List = require('java-core.utils.list')
local Manager = require('pkgm.manager')

local server = require('java-core.ls.servers.jdtls')

local M = {}

---comment
---@param config java.Config
function M.setup(config)
	local jdtls_plugins = List:new()

	if config.java_test.enable then
		jdtls_plugins:push('java-test')
	end

	if config.java_debug_adapter.enable then
		jdtls_plugins:push('java-debug')
	end

	if config.spring_boot_tools.enable then
		jdtls_plugins:push('spring-boot-tools')

		local spring_boot_root = Manager:get_install_dir('spring-boot-tools', config.spring_boot_tools.version)

		require('spring_boot').setup({
			ls_path = path.join(spring_boot_root, 'extension', 'language-server'),
		})

		require('spring_boot').init_lsp_commands()
	end

	local default_config = server.get_config({
		config = config,
		plugins = jdtls_plugins,
	})

	vim.lsp.config('jdtls', default_config)
end

return M
