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
			require('java').setup({
				jdk = {
					auto_install = false,
				},
				log = {
					use_console = false,
					level = 'debug',
				},
			})
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

local k = vim.keymap.set

k('n', '<c-q>', '<cmd>q<CR>')

if colemak then
	k('n', '<c-l>', '<c-i>')
	k('n', 'E', 'K')
	k('n', 'H', 'I')
	k('n', 'K', 'N')
	k('n', 'L', 'E')
	k('n', 'N', 'J')
	k('n', 'e', '<up>')
	k('n', 'h', 'i')
	k('n', 'i', '<right>')
	k('n', 'j', 'm')
	k('n', 'k', 'n')
	k('n', 'l', 'e')
	k('n', 'm', '<left>')
	k('n', 'n', '<down>')
end

vim.api.nvim_create_autocmd('LspAttach', {
	callback = function(args)
		vim.lsp.completion.enable(true, args.data.client_id, args.buf, { autotrigger = true })
		k('i', '<C-Space>', function()
			vim.lsp.completion.get()
		end, { buffer = args.buf })

		if colemak then
			k('i', '<C-n>', '<C-n>', { buffer = args.buf })
			k('i', '<C-e>', '<C-p>', { buffer = args.buf })
		end
	end,
})

k('n', ']d', function()
	vim.diagnostic.jump({ count = 1, float = true })
end, { desc = 'Jump to next diagnostic' })

k('n', '[d', function()
	vim.diagnostic.jump({ count = -1, float = true })
end, { desc = 'Jump to previous diagnostic' })

k('n', '<leader>ta', vim.lsp.buf.code_action, {})

-- DAP keymaps
k('n', '<leader>dd', function()
	require('dap').toggle_breakpoint()
end, { desc = 'Toggle breakpoint' })

k('n', '<leader>dc', function()
	require('dap').continue()
end, { desc = 'Continue' })

k('n', '<leader>dn', function()
	require('dap').step_over()
end, { desc = 'Step over' })

k('n', '<leader>di', function()
	require('dap').step_into()
end, { desc = 'Step into' })

k('n', '<leader>do', function()
	require('dap').step_out()
end, { desc = 'Step out' })

k('n', '<leader>dr', function()
	require('dap').repl.open()
end, { desc = 'Open REPL' })

k('n', '<leader>dl', function()
	require('dap').run_last()
end, { desc = 'Run last' })

k('n', '<leader>dt', function()
	require('dap').terminate()
end, { desc = 'Terminate' })

k('n', 'gd', function()
	vim.lsp.buf.definition()
end, { desc = 'Terminate' })

k('n', '<leader>m', "<cmd>vnew<Cr><cmd>put = execute('messages')<Cr>")

k('n', '<leader>nn', '<CMD>JavaRunnerRunMain<CR>', { desc = 'Run main' })
k('n', '<leader>ne', '<CMD>JavaRunnerStopMain<CR>', { desc = 'Stop main' })
k('n', '<leader>nt', '<CMD>JavaTestDebugCurrentClass<CR>', { desc = 'Debug test' })
k('n', '<leader>ns', '<CMD>JavaTestRunCurrentClass<CR>', { desc = 'Run test' })

k('t', 'yy', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

k('n', '<c-n>', '<c-w>j', { desc = 'Window down' })
k('n', '<c-e>', '<c-w>k', { desc = 'Window up' })
k('n', '<c-m>', '<c-w>h', { desc = 'Window left' })
k('n', '<c-i>', '<c-w>l', { desc = 'Window right' })
