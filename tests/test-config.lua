local java_core_path = vim.fn.expand('~/Workspace/nvim-java-core')
local java_test_path = vim.fn.expand('~/Workspace/nvim-java-test')

local plug_path = './.test_plugins'

java_core_path = (vim.fn.isdirectory(java_core_path) == 1) and java_core_path
	or (plug_path .. '/nvim-java-core')

java_test_path = (vim.fn.isdirectory(java_test_path) == 1) and java_test_path
	or (plug_path .. '/nvim-java-test')

vim.opt.rtp:append(plug_path .. '/plenary.nvim')
vim.opt.rtp:append(plug_path .. '/nvim-lspconfig')
vim.opt.rtp:append(plug_path .. '/mason.nvim')
vim.opt.rtp:append(java_core_path)
vim.opt.rtp:append(java_test_path)
