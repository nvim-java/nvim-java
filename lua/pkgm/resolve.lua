local Manager = require('pkgm.manager')
local path = require('java-core.utils.path')
local err = require('java-core.utils.errors')
local system = require('java-core.utils.system')

local M = {}

local manager = Manager()

local function has_path(config)
	return config.path ~= nil and config.path ~= ''
end

local function can_auto_install(config)
	return config.auto_install ~= false
end

---@param name string
---@param config { version: string, path?: string, auto_install?: boolean }
---@return string
function M.install(name, config)
	if has_path(config) then
		return config.path
	end

	if not can_auto_install(config) then
		err.throw(('nvim-java: %s auto_install disabled and no path configured'):format(name))
	end

	return manager:install(name, config.version)
end

---@param name string
---@param config { version: string, path?: string }
---@return string
function M.get_install_dir(name, config)
	if has_path(config) then
		return config.path
	end

	return manager:get_install_dir(name, config.version)
end

---@param name string
---@param config { version: string, path?: string }
---@return string
function M.get_extension_root(name, config)
	if has_path(config) then
		return config.path
	end

	return path.join(M.get_install_dir(name, config), 'extension')
end

---@param config java.Config
---@return string
function M.get_jdtls_root(config)
	return M.get_install_dir('jdtls', config.jdtls)
end

---@param config java.Config
---@return string
function M.get_lombok_path(config)
	if has_path(config.lombok) then
		return config.lombok.path
	end

	local lombok_root = M.get_install_dir('lombok', config.lombok)
	local lombok_jar_pattern = path.join(lombok_root, 'lombok*.jar')
	local lombok_jar = vim.fn.glob(lombok_jar_pattern)

	if lombok_jar == '' then
		err.throw('nvim-java: lombok jar not found at ' .. lombok_jar_pattern)
	end

	return lombok_jar
end

---@param config java.Config
---@return string
function M.get_jdk_home(config)
	if has_path(config.jdk) then
		return config.jdk.path
	end

	if not can_auto_install(config.jdk) then
		err.throw('nvim-java: jdk auto_install disabled and no path configured')
	end

	local jdk_root = M.get_install_dir('openjdk', config.jdk)

	if system.get_os() == 'mac' then
		return vim.fn.glob(path.join(jdk_root, 'jdk-*', 'Contents', 'Home'))
	end

	return vim.fn.glob(path.join(jdk_root, 'jdk-*'))
end

return M
