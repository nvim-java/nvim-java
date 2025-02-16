local log = require('java.utils.log')
local mason_ui = require('mason.ui')
local mason_util = require('java.utils.mason')
local list_util = require('java-core.utils.list')
local notify = require('java-core.utils.notify')
local async = require('java-core.utils.async')
local lazy = require('java.ui.lazy')
local sync = async.sync

local List = require('java-core.utils.list')

local M = {}

---Install mason package dependencies for nvim-java
---@param config java.Config
function M.install(config)
	local mason_default_config = require('mason.settings').current

	local registries = list_util
		:new(config.mason.registries)
		:concat(mason_default_config.registries)

	require('mason').setup({
		registries = registries,
	})
	local packages = M.get_pkg_list(config)
	local is_outdated = mason_util.is_outdated(packages)

	if is_outdated then
		sync(function()
				M.refresh_and_install(packages)
			end)
			.catch(function(err)
				notify.error('Failed to setup nvim-java ' .. tostring(err))
				log.error('failed to setup nvim-java ' .. tostring(err))
			end)
			.run()
	end

	return is_outdated
end

function M.refresh_and_install(packages)
	vim.schedule(function()
		-- lazy covers mason
		-- https://github.com/nvim-java/nvim-java/issues/51
		lazy.close_lazy_if_opened()

		mason_ui.open()
		notify.warn('Please close and re-open after dependecies are installed')
	end)

	mason_util.refresh_registry()
	mason_util.install_pkgs(packages)
end

---Returns a list of dependency packages
---@param config java.Config
---@return table
function M.get_pkg_list(config)
	local deps = List:new({
		{ name = 'jdtls', version = config.jdtls.version },
		{ name = 'lombok-nightly', version = config.lombok.version },
		{ name = 'java-test', version = config.java_test.version },
		{
			name = 'java-debug-adapter',
			version = config.java_debug_adapter.version,
		},
	})

	if config.jdk.auto_install then
		deps:push({ name = 'openjdk-17', version = config.jdk.version })
	end

	if config.spring_boot_tools.enable then
		deps:push({
			name = 'spring-boot-tools',
			version = config.spring_boot_tools.version,
		})
	end

	return deps
end

return M
