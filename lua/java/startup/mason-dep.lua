local log = require('java.utils.log')
local mason_ui = require('mason.ui')
local mason_util = require('java.utils.mason')
local notify = require('java-core.utils.notify')
local async = require('java-core.utils.async')
local lazy = require('java.ui.lazy')
local sync = async.sync

local List = require('java-core.utils.list')

local M = {}

---Install mason package dependencies for nvim-java
---@param config java.Config
function M.install(config)
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
		{ name = 'jdtls', version = 'v1.38.0' },
		{ name = 'lombok-nightly', version = 'nightly' },
		{ name = 'java-test', version = '0.40.1' },
		{ name = 'java-debug-adapter', version = '0.58.0' },
	})

	if config.jdk.auto_install then
		deps:push({ name = 'openjdk-17', version = '17.0.2' })
	end

	if config.spring_boot_tools.enable then
		deps:push({ name = 'spring-boot-tools', version = '1.55.1' })
	end

	return deps
end

return M
