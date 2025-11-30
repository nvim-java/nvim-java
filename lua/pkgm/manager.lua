local class = require('java-core.utils.class')
local path = require('java-core.utils.path')
local downloader_factory = require('pkgm.downloaders.factory')
local extractor_factory = require('pkgm.extractors.factory')
local log = require('java-core.utils.log2')
local default_specs = require('pkgm.specs.init')
local notify = require('java-core.utils.notify')
local err_util = require('java-core.utils.errors')

---@class pkgm.Manager
---@field specs pkgm.PackageSpec[]
local Manager = class()

Manager.packages_root = path.join(vim.fn.stdpath('data'), 'nvim-java', 'packages')

---@param specs? pkgm.PackageSpec[]
function Manager:_init(specs)
	self.specs = specs or default_specs
	log.debug('Manager initialized with ' .. #self.specs .. ' specs')
end

---Download and extract a package
---@param name string
---@param version string
---@return string # Installation directory path
function Manager:install(name, version)
	log.debug('Installing package:', name, version)

	if self:is_installed(name, version) then
		local install_dir = self:get_install_dir(name, version)
		log.debug('Package already installed:', install_dir)
		return install_dir
	end

	notify.info('Installing package ' .. name .. ' version ' .. version)

	local spec = self:find_spec(name, version)
	local url = spec:get_url(name, version)
	local downloaded_file = self:download_package(url)
	local install_dir = self:get_install_dir(name, version)

	log.debug('Install directory:', install_dir)

	self:extract_package(downloaded_file, install_dir)

	log.debug('Package installed successfully:', install_dir)

	return install_dir
end

---Check if package is installed
---@param name string
---@param version string
---@return boolean # true if package is installed
function Manager:is_installed(name, version)
	local install_dir = self:get_install_dir(name, version)
	local installed = vim.fn.isdirectory(install_dir) == 1
	log.debug('Checking if package installed:', name, version, installed)
	return installed
end

---Uninstall a package
---@param name string
---@param version string
---@return boolean|nil # true on success, nil on failure
---@return string|nil # Error message if failed
function Manager:uninstall(name, version)
	log.debug('Uninstalling package:', name, version)
	local install_dir = self:get_install_dir(name, version)

	if vim.fn.isdirectory(install_dir) == 0 then
		log.warn('Package not installed:', install_dir)
		return nil, 'Package not installed'
	end

	log.debug('Deleting directory:', install_dir)
	local result = vim.fn.delete(install_dir, 'rf')
	if result ~= 0 then
		log.error('Failed to delete package directory:', install_dir)
		return nil, 'Failed to delete package directory'
	end

	log.debug('Package uninstalled successfully')
	return true, nil
end

---Find matching spec for package name and version
---@private
---@param name string
---@param version string
---@return pkgm.PackageSpec # Matching spec, or nil if not found
function Manager:find_spec(name, version)
	log.debug('Finding spec for ' .. name .. ' version ' .. version)

	for _, spec in ipairs(self.specs) do
		if spec:is_match(name, version) then
			log.debug('Found matching spec')
			return spec
		end
	end

	local err = string.format('No matching spec for %s version %s', name, version)
	err_util.throw(err)
end

---Get platform-specific URL from package spec
---@private
---@param spec pkgm.PackageSpec
---@param name string
---@param version string
---@return string|nil # URL for current platform, or nil if not available
---@return string|nil # Error message if URL not available
function Manager:get_platform_url(spec, name, version)
	local success, result = pcall(function()
		return spec:get_url(name, version)
	end)

	if not success then
		return nil, result
	end

	return result, nil
end

---Get package installation directory
---@param name string
---@param version string
---@return string # Installation directory path
function Manager:get_install_dir(name, version)
	return path.join(Manager.packages_root, name, version)
end

---Download package from URL
---@private
---@param url string
---@return string # Downloaded file path
function Manager:download_package(url)
	log.debug('Using URL:', url)

	local downloader = downloader_factory.get_downloader({ url = url })

	log.debug('Starting download...')

	local downloaded_file, err = downloader:download()

	if not downloaded_file then
		err_util.throw(err or 'Download failed')
	end

	log.debug('Downloaded to:', downloaded_file)

	return downloaded_file
end

---Extract package to installation directory
---@private
---@param downloaded_file string
---@param install_dir string
function Manager:extract_package(downloaded_file, install_dir)
	local extractor = extractor_factory.get_extractor({
		source = downloaded_file,
		dest = install_dir,
	})

	vim.fn.mkdir(install_dir, 'p')

	log.debug('Starting extraction...')

	local success, err = extractor:extract()

	if not success then
		vim.fn.delete(install_dir, 'rf')
		vim.fn.delete(downloaded_file)
		err_util.throw(err or 'Extraction failed')
	end

	log.debug('Extraction completed')

	vim.fn.delete(downloaded_file)
	log.debug('Cleaned up temporary file')
end

return Manager
