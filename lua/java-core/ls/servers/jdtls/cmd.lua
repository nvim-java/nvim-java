local List = require('java-core.utils.list')
local path = require('java-core.utils.path')
local Manager = require('pkgm.manager')
local conf = require('java.config')
local system = require('java-core.utils.system')
local log = require('java-core.utils.log2')
local err = require('java-core.utils.errors')
local java_version_map = require('java-core.constants.java_version')
local lsp_utils = require('java-core.utils.lsp')

local M = {}

local jdtls_root = Manager:get_install_dir('jdtls', conf.jdtls.version)

--- Returns a function that returns the command to start jdtls
---@param opts { use_lombok: boolean }
function M.get_cmd(opts)
	---@param dispatchers? vim.lsp.rpc.Dispatchers
	---@param config vim.lsp.ClientConfig
	return function(dispatchers, config)
		local cmd = M.get_jvm_args(opts):concat(M.get_jar_args())

		M.validate_java_version()

		log.debug('Starting jdtls with cmd', cmd)

		local result = vim.lsp.rpc.start(cmd, dispatchers, {
			cwd = config.cmd_cwd,
			env = config.cmd_env,
			detached = config.detached,
		})

		return result
	end
end

---@private
---@param opts { use_lombok: boolean }
---@return java-core.List
function M.get_jvm_args(opts)
	local jdtls_config = path.join(jdtls_root, system.get_config_suffix())

	local jvm_args = List:new({
		'java',
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
	if opts.use_lombok then
		local lombok_root = Manager:get_install_dir('lombok', conf.lombok.version)
		local lombok_path = vim.fn.glob(path.join(lombok_root, 'lombok*.jar'))
		jvm_args:push('-javaagent:' .. lombok_path)
	end

	return jvm_args
end

---@private
---@param cwd? string
---@return java-core.List
function M.get_jar_args(cwd)
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
function M.validate_java_version()
	local v = M.get_java_major_version()
	local exp_ver = java_version_map[conf.jdtls.version]

	if v <= exp_ver.from and v >= exp_ver.to then
		local msg = string.format(
			'Java version mismatch: JDTLS %s requires Java %d - %d, but found Java %d',
			conf.jdtls.version,
			exp_ver.from,
			exp_ver.to,
			v
		)

		err.throw(msg)
	end
end

---@private
function M.get_java_major_version()
	local version = vim.fn.system('java -version')
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
