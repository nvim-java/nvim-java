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
local java_core_path = vim.fn.expand('~/Workspace/nvim-java-core')
local java_test_path = vim.fn.expand('~/Workspace/nvim-java-test')

require('lazy').setup({
	{
		'nvim-lua/plenary.nvim',
		lazy = false,
	},
	{
		'nvim-java/nvim-java-test',
		---@diagnostic disable-next-line: assign-type-mismatch
		dir = vim.fn.isdirectory(java_test_path) == 1 and java_test_path or nil,
		lazy = false,
	},
	{
		'nvim-java/nvim-java-core',
		---@diagnostic disable-next-line: assign-type-mismatch
		dir = vim.fn.isdirectory(java_core_path) == 1 and java_core_path or nil,
		lazy = false,
	},
	{
		'neovim/nvim-lspconfig',
		lazy = false,
	},
	{
		'williamboman/mason.nvim',
		lazy = false,
	},
}, {
	root = temp_path,
	lockfile = temp_path .. '/lazy-lock.json',
	defaults = {
		lazy = false,
	},
})
