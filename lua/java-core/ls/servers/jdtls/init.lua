local M = {}

--- Returns jdtls config
---@param opts { use_jdk: boolean, use_lombok: boolean, plugins: string[] }
function M.get_config(opts)
	local conf = require('java-core.ls.servers.jdtls.conf')
	local plugins = require('java-core.ls.servers.jdtls.plugins')
	local cmd = require('java-core.ls.servers.jdtls.cmd')
	local env = require('java-core.ls.servers.jdtls.env')
	local root = require('java-core.ls.servers.jdtls.root')
	local filetype = require('java-core.ls.servers.jdtls.filetype')
	local log = require('java-core.utils.log2')

	log.debug('get_config called with opts:', opts)

	local base_conf = vim.deepcopy(conf, true)

	base_conf.cmd = cmd.get_cmd(opts)
	base_conf.cmd_env = env.get_env(opts)
	base_conf.init_options.bundles = plugins.get_plugins(opts)
	base_conf.root_markers = root.get_root_markers()
	base_conf.filetypes = filetype.get_filetypes()

	return base_conf
end

return M
