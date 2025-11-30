local class = require('java-core.utils.class')
local log = require('java-core.utils.log2')
local system = require('java-core.utils.system')
local err = require('java-core.utils.errors')

---@class pkgm.VersionRange
---@field from string
---@field to string

---@alias pkgm.UrlValue string|table<string, pkgm.UrlValue>

---@class pkgm.BaseSpecConfig
---@field name string
---@field version string|'*'
---@field version_range? pkgm.VersionRange
---@field urls? table<string, pkgm.UrlValue>
---@field url? string|pkgm.UrlValue
---@field [string] string

---@class pkgm.BaseSpec: pkgm.PackageSpec
local BaseSpec = class()

---@param config pkgm.BaseSpecConfig
function BaseSpec:_init(config)
	log.debug('Initializing BaseSpec with config: ' .. vim.inspect(config))

	self._name = config.name
	self._version = config.version
	self._version_range = config.version_range
	self._template_vars = {}

	if not config.url and not config.urls then
		err.throw('BaseSpec: Neither url nor urls provided')
	end

	self._url = config.url
	self._urls = config.urls

	for key, value in pairs(config) do
		if key ~= 'name' and key ~= 'version' and key ~= 'version_range' and key ~= 'urls' and key ~= 'url' then
			self._template_vars[key] = value
		end
	end

	log.debug('Template vars: ' .. vim.inspect(self._template_vars))
end

---@return string
function BaseSpec:get_name()
	log.debug('get_name() returning: ' .. self._name)
	return self._name
end

---@return string
function BaseSpec:get_version()
	log.debug('get_version() returning: ' .. self._version)
	return self._version
end

---@param name string
---@param version string
---@return boolean
function BaseSpec:is_match(name, version)
	local version_desc = self._version or 'range'
	log.debug(
		'is_match() checking name='
			.. name
			.. ' version='
			.. version
			.. ' against spec name='
			.. self._name
			.. ' spec version='
			.. version_desc
	)

	if name ~= self._name then
		log.debug('Name mismatch')
		return false
	end

	if self._version == '*' then
		log.debug('Wildcard version match')
		return true
	end

	if self._version_range then
		local in_range = self:is_version_in_range(version, self._version_range.from, self._version_range.to)
		log.debug('Version range check: ' .. tostring(in_range))
		return in_range
	end

	local exact_match = version == self._version
	log.debug('Exact version match: ' .. tostring(exact_match))
	return exact_match
end

---@param name string
---@param version string
---@return string
function BaseSpec:get_url(name, version)
	log.debug('get_url() called with name=' .. name .. ' version=' .. version)

	if self._url then
		log.debug('Resolving url')
		local url_template = self:resolve_hierarchical_url(self._url)
		return self:parse_url_template(url_template, name, version)
	end

	if not self._urls then
		err.throw('BaseSpec: Neither url nor urls provided')
	end

	log.debug('Resolving urls table')
	local url_template = self:resolve_hierarchical_url(self._urls)

	if not url_template then
		err.throw('BaseSpec: No url found for current system configuration')
	end

	return self:parse_url_template(url_template, name, version)
end

---@private
---@param url_value string|table
---@return string|nil
function BaseSpec:resolve_hierarchical_url(url_value)
	if type(url_value) == 'string' then
		log.debug('URL is string: ' .. url_value)
		return url_value
	end

	if type(url_value) ~= 'table' then
		log.error('URL value must be string or table')
		return nil
	end

	local platform = system.get_os()
	log.debug('Platform: ' .. platform)

	local platform_value = url_value[platform]
	if not platform_value then
		log.error('No URL for platform: ' .. platform)
		return nil
	end

	if type(platform_value) == 'string' then
		log.debug('Platform-specific URL: ' .. platform_value)
		return platform_value
	end

	local arch = system.get_arch()
	log.debug('Architecture: ' .. arch)

	local arch_value = platform_value[arch]
	if not arch_value then
		log.error('No URL for architecture: ' .. arch)
		return nil
	end

	if type(arch_value) == 'string' then
		log.debug('Architecture-specific URL: ' .. arch_value)
		return arch_value
	end

	local bit_depth = system.get_bit_depth()
	log.debug('Bit depth: ' .. bit_depth)

	local bit_value = arch_value[bit_depth]
	if not bit_value or type(bit_value) ~= 'string' then
		log.error('No URL for bit depth: ' .. bit_depth)
		return nil
	end

	log.debug('Bit-depth-specific URL: ' .. bit_value)
	return bit_value
end

---@private
---@param url_template string
---@param name string
---@param version string
---@return string
function BaseSpec:parse_url_template(url_template, name, version)
	local vars = vim.tbl_extend('force', {
		name = name,
		version = version,
	}, self._template_vars)

	return self:parse_template(url_template, vars)
end

---@private
---@param version string
---@param from string
---@param to string
---@return boolean
function BaseSpec:is_version_in_range(version, from, to)
	log.debug('Checking if ' .. version .. ' is between ' .. from .. ' and ' .. to)
	return version >= from and version <= to
end

---@protected
---@param template string
---@param vars table<string, string>
---@return string
function BaseSpec:parse_template(template, vars)
	log.debug('Parsing template: ' .. template)
	local result = template

	for key, value in pairs(vars) do
		local pattern = '{{' .. key .. '}}'
		result = result:gsub(pattern, value)
		log.debug('Replaced ' .. pattern .. ' with ' .. value)
	end

	log.debug('Parsed result: ' .. result)
	return result
end

return BaseSpec
