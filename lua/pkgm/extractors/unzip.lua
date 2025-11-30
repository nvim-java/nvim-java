local class = require('java-core.utils.class')
local log = require('java-core.utils.log2')

---@class java-core.Unzip
---@field source string
---@field dest string
local Unzip = class()

---@class java-core.UnzipOpts
---@field source string Path to zip file
---@field dest string Destination directory

---@param opts java-core.UnzipOpts
function Unzip:_init(opts)
	self.source = opts.source
	self.dest = opts.dest
end

---Extract zip file using unzip
---@return boolean|nil # true on success, nil on failure
---@return string|nil # Error message if failed
function Unzip:extract()
	log.debug('unzip extracting:', self.source, 'to', self.dest)
	local cmd = string.format('unzip -q -o %s -d %s', vim.fn.shellescape(self.source), vim.fn.shellescape(self.dest))
	log.debug('unzip command:', cmd)

	local result = vim.fn.system(cmd)
	local exit_code = vim.v.shell_error

	if exit_code ~= 0 then
		log.error('unzip extraction failed:', exit_code, result)
		return nil, string.format('unzip failed (exit %d): %s', exit_code, result)
	end

	log.debug('unzip extraction completed')
	return true, nil
end

return Unzip
