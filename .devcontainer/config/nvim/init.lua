local colemak = true

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

-- Setup lazy.nvim
require('lazy').setup({
	{
		'nvim-java/nvim-java',
		dir = '/workspaces/nvim-java',
		config = function()
			require('java').setup()
			vim.lsp.config('jdtls', {
				handlers = {
					['language/status'] = function(_, data)
						vim.notify(data.message, vim.log.levels.INFO)
					end,

					['$/progress'] = function(_, data)
						vim.notify(data.value.message, vim.log.levels.INFO)
					end,
				},
			})
			vim.lsp.enable('jdtls')
		end,
	},
})

-- Basic settings
vim.g.mapleader = ' '
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = false
vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }

vim.keymap.set('n', '<c-q>', '<cmd>q<CR>')

if colemak then
	vim.keymap.set('n', '<c-l>', '<c-i>')
	vim.keymap.set('n', 'E', 'K')
	vim.keymap.set('n', 'H', 'I')
	vim.keymap.set('n', 'K', 'N')
	vim.keymap.set('n', 'L', 'E')
	vim.keymap.set('n', 'N', 'J')
	vim.keymap.set('n', 'e', '<up>')
	vim.keymap.set('n', 'h', 'i')
	vim.keymap.set('n', 'i', '<right>')
	vim.keymap.set('n', 'j', 'm')
	vim.keymap.set('n', 'k', 'n')
	vim.keymap.set('n', 'l', 'e')
	vim.keymap.set('n', 'm', '<left>')
	vim.keymap.set('n', 'n', '<down>')
end

vim.api.nvim_create_autocmd('LspAttach', {
	callback = function(args)
		vim.lsp.completion.enable(true, args.data.client_id, args.buf, { autotrigger = true })
		vim.keymap.set('i', '<C-Space>', function()
			vim.lsp.completion.get()
		end, { buffer = args.buf })

		if colemak then
			vim.keymap.set('i', '<C-n>', '<C-n>', { buffer = args.buf })
			vim.keymap.set('i', '<C-e>', '<C-p>', { buffer = args.buf })
		end
	end,
})

vim.keymap.set('n', ']d', function()
	vim.diagnostic.jump({ count = 1, float = true })
end, { desc = 'Jump to next diagnostic' })

vim.keymap.set('n', '[d', function()
	vim.diagnostic.jump({ count = -1, float = true })
end, { desc = 'Jump to previous diagnostic' })

vim.keymap.set('n', '<leader>ta', vim.lsp.buf.code_action, {})

-- DAP keymaps
vim.keymap.set('n', '<leader>dd', function()
	require('dap').toggle_breakpoint()
end, { desc = 'Toggle breakpoint' })

vim.keymap.set('n', '<leader>dc', function()
	require('dap').continue()
end, { desc = 'Continue' })

vim.keymap.set('n', '<leader>dn', function()
	require('dap').step_over()
end, { desc = 'Step over' })

vim.keymap.set('n', '<leader>di', function()
	require('dap').step_into()
end, { desc = 'Step into' })

vim.keymap.set('n', '<leader>do', function()
	require('dap').step_out()
end, { desc = 'Step out' })

vim.keymap.set('n', '<leader>dr', function()
	require('dap').repl.open()
end, { desc = 'Open REPL' })

vim.keymap.set('n', '<leader>dl', function()
	require('dap').run_last()
end, { desc = 'Run last' })

vim.keymap.set('n', '<leader>dt', function()
	require('dap').terminate()
end, { desc = 'Terminate' })

vim.keymap.set('n', 'gd', function()
	vim.lsp.buf.definition()
end, { desc = 'Terminate' })

vim.keymap.set('n', '<leader>m', "<cmd>vnew<Cr><cmd>put = execute('messages')<Cr>")
