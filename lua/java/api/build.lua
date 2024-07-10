local async = require('java-core.utils.async').sync
local get_error_handler = require('java.handlers.error')

local M = {}

---Do a workspace build
---@param is_full_build? boolean
---@return number
function M.full_build_workspace(is_full_build)
	local JavaCoreJdtlsClient = require('java-core.ls.clients.jdtls-client')
	local jdtls = require('java.utils.jdtls2')
	local buf_util = require('java.utils.buffer')
	local notify = require('java-core.utils.notify')

	is_full_build = type(is_full_build) == 'boolean' and is_full_build or true

	return async(function()
			JavaCoreJdtlsClient(jdtls()):java_build_workspace(
				is_full_build,
				buf_util.get_curr_buf()
			)

			notify.info('Workspace build successful!')
		end)
		.catch(get_error_handler('Workspace build failed'))
		.run()
end

return M
