local path = require('java-core.utils.path')
local log = require('java-core.utils.log2')
local system = require('java-core.utils.system')
local resolver = require('pkgm.resolve')

local M = {}

--- @param config java.Config
function M.get_env(config)
	if not config.jdk.auto_install and not config.jdk.path then
		log.debug('config.jdk.auto_install disabled and config.jdk.path unset, returning empty env')
		return {}
	end

	local java_home = resolver.get_jdk_home(config)

	local java_bin = path.join(java_home, 'bin')

	local separator = system.get_os() == 'win' and ';' or ':'

	local env = {
		['PATH'] = java_bin .. separator .. vim.fn.getenv('PATH'),
		['JAVA_HOME'] = java_home,
	}

	log.debug('env set - JAVA_HOME:', env.JAVA_HOME, 'PATH:', env.PATH)

	return env
end

return M
