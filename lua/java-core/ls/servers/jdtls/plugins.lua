local M = {}

function M.get_plugin_config_map(config)
	return {
		['java-test'] = config.java_test,
		['java-debug'] = config.java_debug_adapter,
		['spring-boot-tools'] = config.spring_boot_tools,
	}
end

---Returns a list of .jar file paths for given list of jdtls plugins
---@param config java.Config
---@param plugins string[]
---@return string[] # list of .jar file paths
function M.get_plugins(config, plugins)
	local file = require('java-core.utils.file')
	local List = require('java-core.utils.list')
	local path = require('java-core.utils.path')
	local err = require('java-core.utils.errors')
	local str = require('java-core.utils.str')
	local resolver = require('pkgm.resolve')

	local plugin_config_map = M.get_plugin_config_map(config)

	return List:new(plugins)
		:map(function(plugin_name)
			local plugin_config = plugin_config_map[plugin_name]

			local plugin_root = resolver.get_extension_root(plugin_name, plugin_config)
			local package_json_str = vim.fn.readfile(path.join(plugin_root, 'package.json'))
			local package_json = vim.json.decode(table.concat(package_json_str, '\n'))
			local java_extensions = package_json.contributes.javaExtensions

			local ext_jars = file.resolve_paths(plugin_root, java_extensions)

			if #ext_jars ~= #java_extensions then
				err.throw(
					str
						.multiline('Failed to load some jars for "%s"', 'Expected %d jars but only %d found')
						:format(plugin_name, #java_extensions, #ext_jars)
				)
			end

			return ext_jars
		end)
		:flatten()
end

return M
