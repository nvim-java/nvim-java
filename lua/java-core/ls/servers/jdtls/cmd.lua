local List = require('java-core.utils.list')
local path = require('java-core.utils.path')
local Manager = require('pkgm.manager')
local system = require('java-core.utils.system')
local log = require('java-core.utils.log2')
local err = require('java-core.utils.errors')
local java_version_map = require('java-core.constants.java_version')
local lsp_utils = require('java-core.utils.lsp')

local M = {}

--- Returns a function that returns the command to start jdtls
---@param config java.Config
function M.get_cmd(config)
	---@param dispatchers? vim.lsp.rpc.Dispatchers
	---@param lsp_config vim.lsp.ClientConfig
	return function(dispatchers, lsp_config)
		local cmd = M.get_jvm_args(config):concat(M.get_jar_args(config))

		-- NOTE: eventhough we are setting the PATH env var, due to a bug, it's not
		-- working on Windows. So just lanching 'java' will result in executing the
		-- system java. So as a workaround, we use the absolute path to java instead
		-- So following check is not needed when we have auto_install set to true
		-- @see https://github.com/neovim/neovim/issues/36818
		if not config.jdk.auto_install then
			M.validate_java_version(config, lsp_config.cmd_env)
		end

		log.debug('Starting jdtls with cmd', cmd)

		local result = vim.lsp.rpc.start(cmd, dispatchers, {
			cwd = lsp_config.cmd_cwd,
			env = lsp_config.cmd_env,
			detached = lsp_config.detached,
		})

		return result
	end
end

---@private
---@param config java.Config
---@return java-core.List
function M.get_jvm_args(config)
	local use_lombok = config.lombok.enable
	local jdtls_root = Manager:get_install_dir('jdtls', config.jdtls.version)
	local jdtls_config = path.join(jdtls_root, system.get_config_suffix())

	local java_exe = 'java'

	-- NOTE: eventhough we are setting the PATH env var, due to a bug, it's not
	-- working on Windows. So we are using the absolute path to java instead
	-- @see https://github.com/neovim/neovim/issues/36818
	if config.jdk.auto_install then
		local jdk_root = Manager:get_install_dir('openjdk', config.jdk.version)
		local java_home
		if system.get_os() == 'mac' then
			java_home = vim.fn.glob(path.join(jdk_root, 'jdk-*', 'Contents', 'Home'))
		else
			java_home = vim.fn.glob(path.join(jdk_root, 'jdk-*'))
		end

		java_exe = path.join(java_home, 'bin', 'java')
	end

	local jvm_args = List:new({
		java_exe,
		'-Declipse.application=org.eclipse.jdt.ls.core.id1',
		'-Dosgi.bundles.defaultStartLevel=4',
		'-Declipse.product=org.eclipse.jdt.ls.core.product',
		'-Dosgi.checkConfiguration=true',
		'-Dosgi.sharedConfiguration.area=' .. jdtls_config,
		'-Dosgi.sharedConfiguration.area.readOnly=true',
		'-Dosgi.configuration.cascaded=true',
		'-Xms1G',
		'--add-modules=ALL-SYSTEM',

		'--add-opens',
		'java.base/java.util=ALL-UNNAMED',

		'--add-opens',
		'java.base/java.lang=ALL-UNNAMED',
	})

	-- Adding lombok
	if use_lombok then
		local lombok_root = Manager:get_install_dir('lombok', config.lombok.version)
		local lombok_path = vim.fn.glob(path.join(lombok_root, 'lombok*.jar'))
		jvm_args:push('-javaagent:' .. lombok_path)
	end

	return jvm_args
end

---@private
---@param config java.Config
---@param cwd? string
---@return java-core.List
function M.get_jar_args(config, cwd)
	local jdtls_root = Manager:get_install_dir('jdtls', config.jdtls.version)
	cwd = cwd or vim.fn.getcwd()

	local launcher_reg = path.join(jdtls_root, 'plugins', 'org.eclipse.equinox.launcher_*.jar')
	local equinox_launcher = vim.fn.glob(path.join(jdtls_root, 'plugins', 'org.eclipse.equinox.launcher_*.jar'))

	if equinox_launcher == '' then
		-- stylua: ignore
		local msg = string.format('JDTLS equinox launcher not found. Expected path: %s. ', launcher_reg)
		err.throw(msg)
	end

	return List:new({
		'-jar',
		equinox_launcher,

		'-configuration',
		lsp_utils.get_jdtls_cache_conf_path(),

		'-data',
		lsp_utils.get_jdtls_cache_data_path(cwd),
	})
end

---@private
---@param config java.Config
---@param env table
function M.validate_java_version(config, env)
	local curr_ver = M.get_java_major_version(env)
	local exp_ver = java_version_map[config.jdtls.version]

	if not (curr_ver >= exp_ver.to and curr_ver <= exp_ver.from) then
		local msg = string.format(
			'Java version mismatch: JDTLS %s requires Java %d <= java >= %d, but found Java %d',
			config.jdtls.version,
			exp_ver.from,
			exp_ver.to,
			curr_ver
		)

		err.throw(msg)
	end
end

---@private
---@param env table
function M.get_java_major_version(env)
	local proc = vim.system({ 'java', '-version' }, { env = env }):wait()
	local version = proc.stderr or proc.stdout or ''

	local major = version:match('version (%d+)')
		or version:match('version "(%d+)')
		or version:match('openjdk (%d+)')
		or version:match('java (%d+)')

	if major then
		return tonumber(major)
	end

	local msg = 'Could not determine java version from::' .. version
	err.throw(msg)
end

return M
