local cwd = vim.fn.getcwd()
vim.opt.runtimepath:prepend(cwd)

--[[
-- plugin name will be used to reload the loaded modules
--]]
local package_name = 'java'

-- add the escape character to special characters
local escape_pattern = function(text)
	return text:gsub('([^%w])', '%%%1')
end

-- unload loaded modules by the matching text
local unload_packages = function()
	local esc_package_name = escape_pattern(package_name)

	for module_name, _ in pairs(package.loaded) do
		if string.find(module_name, esc_package_name) then
			package.loaded[module_name] = nil
		end
	end
end

-- executes the run method in the package
local run_action = function()
	vim.cmd.messages('clear')

	require(package_name).__run()
end

-- unload and run the function from the package
function _G.Reload_and_run()
	unload_packages()
	run_action()
end

---@diagnostic disable-next-line: undefined-global
local set_keymap = vim.api.nvim_set_keymap

set_keymap('n', '<leader><leader>r', '<cmd>luafile dev/init.lua<cr>', {})
set_keymap('n', '<leader><leader>w', '<cmd>lua Reload_and_run()<cr>', {})
