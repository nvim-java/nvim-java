local log = require('java.utils.log')
local mason_reg = require('mason-registry')

local M = {}

local dependecies = {
	{ name = 'jdtls', version = 'v1.29.0' },
	{ name = 'java-test', version = '0.40.2' },
	{ name = 'java-debug-adapter', version = '0.52.0' },
}

---Install mason package dependencies for nvim-java
function M.install_dependencies()
	log.info('check mason dependecies')

	for _, dep in ipairs(dependecies) do
		if not M.is_installed(dep.name, dep.version) then
			log.fmt_info('installing mason pkg: %s', dep.name)

			local pkg = mason_reg.get_package(dep.name)

			pkg:install({
				version = dep.version,
				force = true,
			})
		end
	end
end

---Returns true if the package and its expected version is already installed
---@param pkg_name string name of the package
---@param expc_version string expected version of the package
---@return boolean true if the package and its version is already installed
function M.is_installed(pkg_name, expc_version)
	local pkg = mason_reg.get_package(pkg_name)

	if not pkg:is_installed() then
		return false
	end

	---@type string | nil
	local installed_version

	pkg:get_installed_version(function(ok, version)
		if ok then
			installed_version = version
		end
	end)

	if installed_version == expc_version then
		return true
	end

	return false
end

return M
