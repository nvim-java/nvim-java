local log = require('java.utils.log')
local mason_reg = require('mason-registry')
local async = require('java-core.utils.async')
local await = async.wait_handle_ok

local M = {}

function M.is_available(package_name, package_version)
	-- guard clause
	local has_pkg = mason_reg.has_package(package_name)
	if not has_pkg then
		return false
	end

	-- check
	local pkg = mason_reg.get_package(package_name)
	local version = pkg:get_installed_version()
	local has_version = version == package_version

	return has_version
end

function M.is_installed(package_name, package_version)
	-- guard clause
	local pkg = mason_reg.get_package(package_name)
	local is_installed = pkg:is_installed()
	if not is_installed then
		return false
	end

	-- check
	local installed_version = pkg:get_installed_version()
	is_installed = installed_version == package_version

	return is_installed
end

function M.is_outdated(packages)
	for _, pkg in ipairs(packages) do
		if not M.is_available(pkg.name, pkg.version) then
			return true
		end

		if not M.is_installed(pkg.name, pkg.version) then
			return true
		end
	end
end

function M.refresh_registry()
	await(function(callback)
		mason_reg.update(callback)
	end)
end

function M.install_pkgs(packages)
	log.info('check mason dependecies')

	for _, dep in ipairs(packages) do
		if not M.is_installed(dep.name, dep.version) then
			local pkg = mason_reg.get_package(dep.name)

			pkg:install({
				version = dep.version,
				force = true,
			})
		end
	end
end

return M
