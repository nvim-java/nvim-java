local assert = require('luassert')

describe('Package resolver', function()
	local resolver
	local Manager
	local original_install
	local original_get_install_dir

	before_each(function()
		package.loaded['pkgm.resolve'] = nil

		Manager = require('pkgm.manager')
		original_install = Manager.install
		original_get_install_dir = Manager.get_install_dir

		resolver = require('pkgm.resolve')
	end)

	after_each(function()
		Manager.install = original_install
		Manager.get_install_dir = original_get_install_dir
	end)

	it('uses configured paths without installing packages', function()
		Manager.install = function()
			error('install should not be called')
		end

		local install_dir = resolver.install('jdtls', {
			version = '1.54.0',
			path = '/opt/jdtls',
		})

		assert.equals('/opt/jdtls', install_dir)
	end)

	it('installs packages when no path is configured and auto_install is enabled', function()
		local installed_name
		local installed_version

		Manager.install = function(_, name, version)
			installed_name = name
			installed_version = version
			return '/downloaded/' .. name .. '/' .. version
		end

		local install_dir = resolver.install('jdtls', {
			version = '1.54.0',
			auto_install = true,
		})

		assert.equals('jdtls', installed_name)
		assert.equals('1.54.0', installed_version)
		assert.equals('/downloaded/jdtls/1.54.0', install_dir)
	end)

	it('fails when auto_install is disabled and no path is configured', function()
		local log = require('java-core.utils.log2')
		local original_notify = vim.notify
		local original_log_error = log.error

		vim.notify = function() end
		log.error = function() end

		local ok, assertion_err = pcall(function()
			assert.has_error(function()
				resolver.install('jdtls', {
					version = '1.54.0',
					auto_install = false,
				})
			end, 'nvim-java: jdtls auto_install disabled and no path configured')
		end)

		vim.notify = original_notify
		log.error = original_log_error

		if not ok then
			error(assertion_err)
		end
	end)

	it('resolves external vscode extension roots directly', function()
		local extension_root = resolver.get_extension_root('java-test', {
			version = '0.43.2',
			path = '/opt/vscode-java-test',
		})

		assert.equals('/opt/vscode-java-test', extension_root)
	end)

	it('resolves downloaded vscode extension roots from the package layout', function()
		Manager.get_install_dir = function(_, name, version)
			return '/downloaded/' .. name .. '/' .. version
		end

		local extension_root = resolver.get_extension_root('java-test', {
			version = '0.43.2',
		})

		assert.equals('/downloaded/java-test/0.43.2/extension', extension_root)
	end)

	it('uses exact lombok jar paths when configured', function()
		local lombok_path = resolver.get_lombok_path({
			lombok = {
				version = '1.18.42',
				path = '/opt/lombok.jar',
			},
		})

		assert.equals('/opt/lombok.jar', lombok_path)
	end)

	it('uses jdk paths as java home when configured', function()
		local jdk_home = resolver.get_jdk_home({
			jdk = {
				version = '25',
				path = '/opt/jdk',
			},
		})

		assert.equals('/opt/jdk', jdk_home)
	end)
end)
