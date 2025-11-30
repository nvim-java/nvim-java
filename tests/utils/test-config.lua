local jdtls_cache_path = vim.fn.stdpath('cache') .. '/jdtls'
local gradle_cache_path = vim.fn.expand('~') .. '/.gradle'

print('removing cache')
vim.fn.delete(jdtls_cache_path, 'rf')
vim.fn.delete(gradle_cache_path, 'rf')

vim.o.swapfile = false
vim.o.backup = false
vim.o.writebackup = false

local temp_path = './.test_plugins'

vim.opt.runtimepath:append(temp_path .. '/')
vim.opt.runtimepath:append(temp_path .. '/nui.nvim')
vim.opt.runtimepath:append(temp_path .. '/spring-boot.nvim')
vim.opt.runtimepath:append(temp_path .. '/nvim-dap')
vim.opt.runtimepath:append('.')

local is_nixos = vim.fn.filereadable('/etc/NIXOS') == 1

require('java').setup({
	jdk = {
		auto_install = not is_nixos,
	},
})

vim.lsp.enable('jdtls')
