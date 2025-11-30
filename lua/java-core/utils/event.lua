local M = {}

---@param opts { once?: boolean, group?: number, callback: fun(client: vim.lsp.Client) }
function M.on_jdtls_attach(opts)
	local id

	id = vim.api.nvim_create_autocmd('LspAttach', {
		group = opts.group,
		callback = function(args)
			local client = vim.lsp.get_client_by_id(args.data.client_id)

			if client and client.name == 'jdtls' then
				opts.callback(client)

				if opts.once then
					vim.api.nvim_del_autocmd(id)
				end
			end
		end,
	})
end

return M
