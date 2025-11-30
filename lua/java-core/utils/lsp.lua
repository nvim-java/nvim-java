local M = {}

---Get JDTLS LSP client
---@return vim.lsp.Client
function M.get_jdtls()
	local err = require('java-core.utils.errors')

	local clients = vim.lsp.get_clients({ name = 'jdtls' })

	if #clients == 0 then
		vim.print(debug.traceback())
		err.throw('No JDTLS client found')
	end

	return clients[1]
end

--- Returns the path to the jdtls cache directory
---@return string
function M.get_jdtls_cache_root_path()
	local path = require('java-core.utils.path')
	local cache_root = path.join(vim.fn.stdpath('cache'), 'jdtls')
	return cache_root
end

--- Returns the path to the jdtls config file
---@return string
function M.get_jdtls_cache_conf_path()
	local path = require('java-core.utils.path')
	local cache_root = M.get_jdtls_cache_root_path()
	local conf_path = path.join(cache_root, 'config')
	return conf_path
end

--- Returns the path to the workspace cache directory
---@param cwd string
---@return string
function M.get_jdtls_cache_data_path(cwd)
	cwd = cwd or vim.fn.getcwd()

	local path = require('java-core.utils.path')
	local cache_root = M.get_jdtls_cache_root_path()
	local workspace_path = path.join(cache_root, 'workspace', 'proj_' .. vim.fn.sha256(cwd))
	return workspace_path
end

---Restart given LSP server
---@param ls string
function M.restart_ls(ls)
	if vim.lsp.config[ls] == nil then
		vim.notify(("Invalid server name '%s'"):format(ls))
	else
		vim.lsp.enable(ls, false)

		vim.iter(vim.lsp.get_clients({ name = ls })):each(function(client)
			client:stop(true)
		end)
	end

	local timer = assert(vim.uv.new_timer())
	timer:start(500, 0, function()
		vim.schedule_wrap(vim.lsp.enable)(ls)
	end)
end

return M
