local M = {}

local message = 'require("java").setup() is called more than once'
	.. '\nnvim-java will continue to setup but nvim-java configurations might not work as expected'
	.. '\nThis might be due to old installation instructions.'
	.. '\nPlease check the latest guide at https://github.com/nvim-java/nvim-java#hammer-how-to-install'
	.. '\nIf you know what you are doing, you can disable the check from the config'
	.. '\nhttps://github.com/nvim-java/nvim-java#wrench-configuration'

function M.is_valid()
	if vim.g.nvim_java_setup_is_called then
		return {
			success = false,
			continue = true,
			message = message,
		}
	end

	vim.g.nvim_java_setup_is_called = true

	return {
		success = true,
		continue = true,
	}
end

return M
