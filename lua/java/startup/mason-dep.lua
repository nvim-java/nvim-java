local log = require('java.utils.log')
local mason_ui = require('mason.ui')
local mason_util = require('java.utils.mason')
local list_util = require('java-core.utils.list')
local notify = require('java-core.utils.notify')
local async = require('java-core.utils.async')
local lazy = require('java.ui.lazy')
local sync = async.sync
local mason_v2 = require('mason.version').MAJOR_VERSION == 2

local List = require('java-core.utils.list')

local M = {}

---Add custom registries to Mason 1.x
---@param registries java.Config
local function add_custom_registries_v1(registries)
	local mason_default_config = require('mason.settings').current

	local new_registries =
		list_util:new(registries):concat(mason_default_config.registries)

	require('mason').setup({
		registries = new_registries,
	})
end

---Add custom registries to Mason 2.x
---@param registries java.Config
local function add_custom_registries_v2(registries)
	for _, reg in ipairs(registries) do
		---@diagnostic disable-next-line: undefined-field
		require('mason-registry').sources:prepend(reg)
	end
end

if mason_v2 then
	M.add_custom_registries = add_custom_registries_v2
else
	M.add_custom_registries = add_custom_registries_v1
end

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
		notify.warn('Please close and re-open after dependencies are installed')
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
