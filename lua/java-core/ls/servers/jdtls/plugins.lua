local file = require('java-core.utils.file')
local List = require('java-core.utils.list')
local Manager = require('pkgm.manager')
local log = require('java-core.utils.log2')

--- @TODO: importing stuff from java main package feels wrong.
--- We should fix this in the future
local config = require('java.config')

local M = {}

local plug_jar_map = {
	['java-test'] = {
		'extension/server/junit-jupiter-api_*.jar',
		'extension/server/junit-jupiter-engine_*.jar',
		'extension/server/junit-jupiter-migrationsupport_*.jar',
		'extension/server/junit-jupiter-params_*.jar',
		'extension/server/junit-platform-commons_*.jar',
		'extension/server/junit-platform-engine_*.jar',
		'extension/server/junit-platform-launcher_*.jar',
		'extension/server/junit-platform-runner_*.jar',
		'extension/server/junit-platform-suite-api_*.jar',
		'extension/server/junit-platform-suite-commons_*.jar',
		'extension/server/junit-platform-suite-engine_*.jar',
		'extension/server/junit-vintage-engine_*.jar',
		'extension/server/org.apiguardian.api_*.jar',
		'extension/server/org.eclipse.jdt.junit4.runtime_*.jar',
		'extension/server/org.eclipse.jdt.junit5.runtime_*.jar',
		'extension/server/org.opentest4j_*.jar',
		'extension/server/com.microsoft.java.test.plugin-*.jar',
	},
	['java-debug'] = {
		'extension/server/com.microsoft.java.debug.plugin-*.jar',
	},
	['spring-boot-tools'] = { 'extension/jars/*.jar' },
}

local plugin_version_map = {
	['java-test'] = config.java_test.version,
	['java-debug'] = config.java_debug_adapter.version,
	['spring-boot-tools'] = config.spring_boot_tools.version,
}

---Returns a list of .jar file paths for given list of jdtls plugins
---@param opts { plugins: string[] }
---@return string[] # list of .jar file paths
function M.get_plugins(opts)
	return List:new(opts.plugins)
		:map(function(plugin_name)
			local version = plugin_version_map[plugin_name]
			local root = Manager:get_install_dir(plugin_name, version)
			local jars = file.resolve_paths(root, plug_jar_map[plugin_name])

			if #jars == 0 then
				-- stylua: ignore
				log.error(string.format( 'No jars found for plugin "%s" (version: %s) at %s', plugin_name, version, root))
				-- stylua: ignore
				error(string.format( 'Failed to load plugin "%s". No jars found at %s', plugin_name, root))
			end

			return jars
		end)
		:flatten()
end

return M
