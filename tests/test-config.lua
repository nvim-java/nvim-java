---@diagnostic disable: assign-type-mismatch
---@param dev_path string
---@param plug_path string
---@return string|nil
local function local_plug(dev_path, plug_path)
	return (vim.fn.isdirectory(dev_path) == 1) and dev_path or plug_path
end

local plug_path = './.test_plugins'

vim.opt.rtp:append(plug_path .. '/plenary.nvim')
vim.opt.rtp:append(plug_path .. '/nvim-lspconfig')
vim.opt.rtp:append(plug_path .. '/mason.nvim')

vim.opt.rtp:append(
	local_plug('~/Workspace/nvim-java-core', plug_path .. '/nvim-java-core')
)

vim.opt.rtp:append(
	local_plug('~/Workspace/nvim-java-test', plug_path .. '/nvim-java-test')
)

vim.opt.rtp:append(
	local_plug('~/Workspace/nvim-java-dap', plug_path .. '/nvim-java-dap')
)
