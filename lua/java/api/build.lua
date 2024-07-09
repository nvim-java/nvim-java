local async = require('java-core.utils.async').sync
local get_error_handler = require('java.handlers.error')

local M = {}

function M.full_build_workspace()
	return async(function()
			local JavaCoreJdtlsClient = require('java-core.ls.clients.jdtls-client')
			local jdtls = require('java.utils.jdtls2')
			local buf_util = require('java.utils.buffer')
			local notify = require('java-core.utils.notify')

			JavaCoreJdtlsClient(jdtls()):java_build_workspace(
				true,
				buf_util.get_curr_buf()
			)

			notify.info('Workspace build successful!')
		end)
		.catch(get_error_handler('Workspace build failed'))
		.run()
end

return M
