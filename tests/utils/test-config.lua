local jdtls_cache_path = vim.fn.stdpath('cache') .. '/jdtls'
local gradle_cache_path = vim.fn.expand('~') .. '/.gradle'

print('removing cache')
vim.fn.delete(jdtls_cache_path, 'rf')
vim.fn.delete(gradle_cache_path, 'rf')

vim.o.swapfile = false
vim.o.backup = false
vim.o.writebackup = false

-- absolute paths so requires keep working after tests :cd elsewhere
local root = vim.fn.getcwd()
local temp_path = root .. '/.test_plugins'

vim.opt.runtimepath:append(temp_path .. '/')
vim.opt.runtimepath:append(temp_path .. '/plenary.nvim')
vim.opt.runtimepath:append(temp_path .. '/nui.nvim')
vim.opt.runtimepath:append(temp_path .. '/spring-boot.nvim')
vim.opt.runtimepath:append(temp_path .. '/nvim-dap')
vim.opt.runtimepath:append(root)

local is_nixos = vim.fn.filereadable('/etc/NIXOS') == 1
local is_ci = vim.env.CI ~= nil

local config = {
	jdk = {
		auto_install = not is_nixos,
	},
}

if is_ci then
	config.log = {
		level = 'debug',
		use_console = true,
	}
end

require('java').setup(config)

-- plenary child nvim runs with --noplugin so user commands never register
vim.cmd('runtime! plugin/java.lua')

vim.lsp.enable('jdtls')
