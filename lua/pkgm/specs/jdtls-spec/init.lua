local class = require('java-core.utils.class')
local BaseSpec = require('pkgm.specs.base-spec')
local version_map = require('pkgm.specs.jdtls-spec.version-map')
local err = require('java-core.utils.errors')

---@class pkgm.JdtlsSpec: pkgm.BaseSpec
local JdtlsSpec = class(BaseSpec)

function JdtlsSpec:_init(config)
	---@diagnostic disable-next-line: undefined-field
	self:super(config)
end

function JdtlsSpec:get_url(name, version)
	---@diagnostic disable-next-line: undefined-field
	local url = self._base.get_url(self, name, version)

	if not version_map[version] then
		local message = string.format(
			[[
		%s@%s is not defined in the version map.
		You can update the version map yourself and create a PR.
		nvim-java/lua/pkgm/specs/jdtls-spec/version-map.lua
		or
		Please create an issue at:
		https://github.com/s1n7ax/nvim-java/issues to add the missing version.
		]],
			name,
			version
		)

		err.throw(message)
	end

	local new_url = self:parse_template(url, {
		timestamp = version_map[version],
	})

	return new_url
end

return JdtlsSpec
