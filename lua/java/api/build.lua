local runner = require('async.runner')
local get_error_handler = require('java.handlers.error')
local ui = require('java.utils.ui')
local jdtls = require('java.utils.jdtls2')

local M = {}

---Do a workspace build
---@param is_full_build? boolean
---@return number
function M.full_build_workspace(is_full_build)
	local JdtlsClient = require('java-core.ls.clients.jdtls-client')
	local buf_util = require('java.utils.buffer')
	local notify = require('java-core.utils.notify')

	is_full_build = type(is_full_build) == 'boolean' and is_full_build or true

	return runner(function()
			JdtlsClient(jdtls()):java_build_workspace(
				is_full_build,
				buf_util.get_curr_buf()
			)

			notify.info('Workspace build successful!')
		end)
		.catch(get_error_handler('Workspace build failed'))
		.run()
end

function M.clean_workspace()
	runner(function()
			local client = jdtls()

			local workpace_path =
				vim.tbl_get(client, 'config', 'init_options', 'workspace')

			local prompt = string.format('Do you want to delete "%s"', workpace_path)

			local choice = ui.select(prompt, { 'Yes', 'No' })

			if choice ~= 'Yes' then
				return
			end

			vim.fn.delete(workpace_path, 'rf')
		end)
		.catch(get_error_handler('Failed to clean up the workspace'))
		.run()
end

return M
