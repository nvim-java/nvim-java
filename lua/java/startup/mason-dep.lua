local log = require('java.utils.log')
local mason_ui = require('mason.ui')
local mason_util = require('java.utils.mason')
local notify = require('java-core.utils.notify')
local async = require('java-core.utils.async')
local lazy = require('java.ui.lazy')
local sync = async.sync

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

function M.get_pkg_list(config)
	local dependecies = {
		{ name = 'jdtls', version = 'v1.31.0' },
		{ name = 'java-test', version = '0.40.1' },
		{ name = 'java-debug-adapter', version = '0.55.0' },
	}

	if config.jdk.auto_install then
		table.insert(dependecies, { name = 'openjdk-17', version = '17.0.2' })
	end

	return dependecies
end

return M
