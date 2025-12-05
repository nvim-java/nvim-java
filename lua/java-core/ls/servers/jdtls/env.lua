local path = require('java-core.utils.path')
local Manager = require('pkgm.manager')
local log = require('java-core.utils.log2')
local system = require('java-core.utils.system')

local M = {}

--- @param config java.Config
function M.get_env(config)
	if not config.jdk.auto_install then
		log.debug('config.jdk.auto_install disabled, returning empty env')
		return {}
	end

	local jdk_root = Manager:get_install_dir('openjdk', config.jdk.version)

	local java_home

	if system.get_os() == 'mac' then
		java_home = vim.fn.glob(path.join(jdk_root, 'jdk-*', 'Contents', 'Home'))
	else
		java_home = vim.fn.glob(path.join(jdk_root, 'jdk-*'))
	end

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
