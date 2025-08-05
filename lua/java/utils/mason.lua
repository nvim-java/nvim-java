local log = require('java.utils.log')
local mason_reg = require('mason-registry')
local async = require('java-core.utils.async')
local await = async.wait_handle_ok
local mason_v2 = require('mason.version').MAJOR_VERSION == 2

local M = {}

function M.is_available(package_name, package_version)
	-- get_package errors if the package is not available in Mason 2.x
	-- it works fine in Mason 1.x this way too.
	local has_pkg, pkg = pcall(mason_reg.get_package, package_name)

	if not has_pkg then
		return false
	end

	local installed_version
	if mason_v2 then
		-- the compiler will complain when Mason 1.x is in use
		---@diagnostic disable-next-line: missing-parameter
		installed_version = pkg:get_installed_version()
	else
		-- the compiler will complain when mason 2.x is in use
		---@diagnostic disable-next-line: param-type-mismatch
		pkg:get_installed_version(function(success, version)
			if success then
				installed_version = version
			end
		end)
	end

	return installed_version == package_version
end

function M.is_installed(package_name, package_version)
	-- get_package errors if the package is not available in Mason 2.x
	-- it works fine in Mason 1.x this way too.
	local found, pkg = pcall(mason_reg.get_package, package_name)

	if not found or not pkg:is_installed() then
		return false
	end

	local installed_version
	if mason_v2 then
		-- the compiler will complain when Mason 1.x is in use
		---@diagnostic disable-next-line: missing-parameter
		installed_version = pkg:get_installed_version()
	else
		-- the compiler will complain when Mason 2.x is in use
		---@diagnostic disable-next-line: param-type-mismatch
		pkg:get_installed_version(function(success, version)
			if success then
				installed_version = version
			end
		end)
	end

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

			-- install errors if installation is already running in Mason 2.x
			local guard
			if mason_v2 then
				-- guard if the package is already installing in Mason 2.x
				-- the compiler will complain about the following line with Mason 1.x
				---@diagnostic disable-next-line: undefined-field
				guard = pkg:is_installing()
			else
				guard = false
			end
			if not guard then
				pkg:install({
					version = dep.version,
					force = true,
				})
			end
		end
	end
end

return M
