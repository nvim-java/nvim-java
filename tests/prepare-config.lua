local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'

---@diagnostic disable: assign-type-mismatch
---@param path string
---@return string|nil
local function local_plug(path)
	return vim.fn.isdirectory(path) == 1 and path or nil
end

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

require('lazy').setup({
	{
		'nvim-lua/plenary.nvim',
		lazy = false,
	},
	{
		'nvim-java/nvim-java-test',
		---@diagnostic disable-next-line: assign-type-mismatch
		dir = local_plug('~/Workspace/nvim-java-test'),
		lazy = false,
	},
	{
		'nvim-java/nvim-java-core',
		---@diagnostic disable-next-line: assign-type-mismatch
		dir = local_plug('~/Workspace/nvim-java-core'),
		lazy = false,
	},
	{
		'nvim-java/nvim-java-dap',
		---@diagnostic disable-next-line: assign-type-mismatch
		dir = local_plug('~/Workspace/nvim-java-dap'),
		lazy = false,
	},
	{
		'neovim/nvim-lspconfig',
		lazy = false,
	},
	{
		'mason-org/mason.nvim',
		lazy = false,
	},
	{
		'MunifTanjim/nui.nvim',
		lazy = false,
	},
}, {
	root = temp_path,
	lockfile = temp_path .. '/lazy-lock.json',
	defaults = {
		lazy = false,
	},
})
