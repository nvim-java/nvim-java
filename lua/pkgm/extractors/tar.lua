local class = require('java-core.utils.class')
local log = require('java-core.utils.log2')
local system = require('java-core.utils.system')

---@class java-core.Tar
---@field source string
---@field dest string
local Tar = class()

---@class java-core.TarOpts
---@field source string Path to tar file (supports .tar, .tar.gz, .tgz, .tar.xz)
---@field dest string Destination directory

---@param opts java-core.TarOpts
function Tar:_init(opts)
	self.source = opts.source
	self.dest = opts.dest
end

---@private
---Check if tar supports --force-local
---@param tar_cmd string
---@return boolean
function Tar:tar_supports_force_local(tar_cmd)
	local ok, out = pcall(vim.fn.system, { tar_cmd, '--help' })
	if not ok then
		return false
	end
	return out:match('%-%-force%-local') ~= nil
end

---Extract tar file using tar
---@return boolean|nil # true on success, nil on failure
---@return string|nil # Error message if failed
function Tar:extract()
	local tar_cmd = vim.fn.executable('gtar') == 1 and 'gtar' or 'tar'
	log.debug('tar extracting:', self.source, 'to', self.dest)
	log.debug('Using tar binary:', tar_cmd)

	local source = self.source
	local dest = self.dest

	-- argv list so no shell quoting is involved (&shell may be pwsh on
	-- Windows nvim nightly)
	local cmd = { tar_cmd, '--no-same-owner' }

	if system.get_os() == 'win' then
		-- Windows: convert backslashes to forward slashes (tar accepts them)
		source = source:gsub('\\', '/')
		dest = dest:gsub('\\', '/')

		if self:tar_supports_force_local(tar_cmd) then
			table.insert(cmd, '--force-local')
		end
	end

	vim.list_extend(cmd, { '-xf', source, '-C', dest })
	log.debug('tar command:', cmd)

	local result = vim.fn.system(cmd)
	local exit_code = vim.v.shell_error

	if exit_code ~= 0 then
		log.error('tar extraction failed:', exit_code, result)
		return nil, string.format('tar failed (exit %d): %s', exit_code, result)
	end

	log.debug('tar extraction completed')
	return true, nil
end

return Tar
