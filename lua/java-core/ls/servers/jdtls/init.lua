local M = {}

--- Returns jdtls config
---@param opts { plugins: string[], config: java.Config }
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

	base_conf.cmd = cmd.get_cmd(opts.config)
	base_conf.cmd_env = env.get_env(opts.config)
	base_conf.init_options.bundles = plugins.get_plugins(opts.config, opts.plugins)
	base_conf.root_markers = root.get_root_markers()
	base_conf.filetypes = filetype.get_filetypes()

	log.debug('jdtls config', base_conf)

	return base_conf
end

return M
