local assert = require('luassert')

describe('JDTLS command', function()
	local cmd = require('java-core.ls.servers.jdtls.cmd')
	local path = require('java-core.utils.path')

	local temp_dir

	before_each(function()
		temp_dir = vim.fn.tempname()
		vim.fn.mkdir(temp_dir, 'p')
	end)

	after_each(function()
		vim.fn.delete(temp_dir, 'rf')
	end)

	it('uses the platform-specific config directory when it exists', function()
		local config_dir = path.join(temp_dir, 'config_mac_arm')
		vim.fn.mkdir(config_dir, 'p')

		assert.equals(config_dir, cmd.get_jdtls_config_path(temp_dir))
	end)

	it('falls back to the os config directory when the platform-specific directory is missing', function()
		local config_dir = path.join(temp_dir, 'config_mac')
		vim.fn.mkdir(config_dir, 'p')

		assert.equals(config_dir, cmd.get_jdtls_config_path(temp_dir))
	end)
end)
