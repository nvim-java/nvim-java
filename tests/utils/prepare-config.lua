local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'

if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		'git',
		'clone',
		'--filter=blob:none',
		'https://github.com/folke/lazy.nvim.git',
		'--branch=stable',
		lazypath,
	})
end

vim.opt.rtp:prepend(lazypath)

local temp_path = './.test_plugins'

-- Setup lazy.nvim
require('lazy').setup({
	{
		'nvim-lua/plenary.nvim',
		lazy = false,
	},
	'MunifTanjim/nui.nvim',
	'mfussenegger/nvim-dap',
	{
		'JavaHello/spring-boot.nvim',
		commit = '218c0c26c14d99feca778e4d13f5ec3e8b1b60f0',
	},
	{
		'nvim-java/nvim-java',
		dir = '.',
		config = function()
			require('java').setup({
				jdk = {
					auto_install = false,
				},
			})
			vim.lsp.enable('jdtls')
		end,
	},
}, {
	root = temp_path,
	lockfile = temp_path .. '/lazy-lock.json',
	defaults = { lazy = false },
})

vim.api.nvim_create_autocmd('LspAttach', {
	callback = function(args)
		-- stylua: ignore
		vim.lsp.completion.enable(true, args.data.client_id, args.buf, { autotrigger = true })
		vim.keymap.set('i', '<C-Space>', function()
			vim.lsp.completion.get()
		end, { buffer = args.buf })
	end,
})
