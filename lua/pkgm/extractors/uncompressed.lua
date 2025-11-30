local class = require('java-core.utils.class')
local log = require('java-core.utils.log2')

---@class java-core.Uncompressed
---@field source string
---@field dest string
local Uncompressed = class()

---@class java-core.UncompressedOpts
---@field source string Path to jar file
---@field dest string Destination directory

---@param opts java-core.UncompressedOpts
function Uncompressed:_init(opts)
	self.source = opts.source
	self.dest = opts.dest
end

---Move jar file to destination
---@return boolean|nil # true on success, nil on failure
---@return string|nil # Error message if failed
function Uncompressed:extract()
	log.debug('Moving uncompressed file:', self.source, 'to', self.dest)

	if not self.source:lower():match('%.jar$') then
		local err = 'Only .jar files are supported'
		log.error(err)
		return nil, err
	end

	local filename = vim.fn.fnamemodify(self.source, ':t')
	local dest_path = vim.fn.resolve(self.dest .. '/' .. filename)

	log.debug('Destination path:', dest_path)

	local success = vim.loop.fs_copyfile(self.source, dest_path)
	if not success then
		local err = string.format('Failed to copy %s to %s', self.source, dest_path)
		log.error(err)
		return nil, err
	end

	log.debug('File move completed')
	return true, nil
end

return Uncompressed
