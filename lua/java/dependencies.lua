local log = require('java.utils.log')

local pkgs = {
	{
		name = 'mason-registry',
		err = [[mason.nvim is not installed. nvim-java requires mason.nvim to install dependecies.
	Please follow the install guide in https://github.com/nvim-java/nvim-java to install nvim-java]],
	},
	{
		name = 'dap',
		err = [[nvim-dap is not installed. nvim-java requires nvim-dap to setup the debugger.
Please follow the install guide in https://github.com/nvim-java/nvim-java to install nvim-java]],
	},
	{
		name = 'lspconfig',
		err = [[nvim-lspconfig is not installed. nvim-lspconfig requires nvim-lspconfig to show diagnostics & auto completion.
Please follow the install guide in https://github.com/nvim-java/nvim-java to install nvim-java]],
	},
}

local M = {}

function M.check()
	log.info('check neovim plugin dependencies')
	M.neovim_plugin_check()
end

function M.neovim_plugin_check()
	for _, pkg in ipairs(pkgs) do
		local ok, _ = pcall(require, pkg.name)

		if not ok then
			log.error(pkg.err)
			error(pkg.err)
		end
	end
end

return M
