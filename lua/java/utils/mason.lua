local log = require('java.utils.log')
local mason_reg = require('mason-registry')
local async = require('java-core.utils.async')
local await = async.wait_handle_ok

local M = {}

function M.is_available(package_name, package_version)
	-- get_package errors if the package is not available in Mason 2.0
	local has_pkg, pkg = pcall(mason_reg.get_package, package_name)

	if not has_pkg then
		return false
	end

	local installed_version = pkg:get_installed_version()

	return installed_version == package_version
end

function M.is_installed(package_name, package_version)
	-- get_package errors if the package is not available in Mason 2.0
	local found, pkg = pcall(mason_reg.get_package, package_name)

	if not found or not pkg:is_installed() then
		return false
	end

	local installed_version = pkg:get_installed_version()

	return installed_version == package_version
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

			-- install errors if installation is already running in Mason 2.0
			if not pkg:is_installing() then
				pkg:install({
					version = dep.version,
					force = true,
				})
			end
		end
	end
end

return M
