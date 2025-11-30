local class = require('java-core.utils.class')
local log = require('java-core.utils.log2')

---@class java-core.PowerShellExtractor
---@field source string
---@field dest string
local PowerShellExtractor = class()

---@class java-core.PowerShellExtractorOpts
---@field source string Path to zip file
---@field dest string Destination directory

---@param opts java-core.PowerShellExtractorOpts
function PowerShellExtractor:_init(opts)
	self.source = opts.source
	self.dest = opts.dest
end

---Extract zip file using PowerShell Expand-Archive
---@return boolean|nil # true on success, nil on failure
---@return string|nil # Error message if failed
function PowerShellExtractor:extract()
	local pwsh = vim.fn.executable('pwsh') == 1 and 'pwsh' or 'powershell'
	log.debug('PowerShell extracting:', self.source, 'to', self.dest)
	log.debug('Using PowerShell binary:', pwsh)

	-- Expand-Archive requires .zip extension
	local source_file = self.source
	if not source_file:lower():match('%.zip$') then
		log.debug('Renaming file to add .zip extension')
		source_file = source_file .. '.zip'
		local ok = vim.fn.rename(self.source, source_file)
		if ok ~= 0 then
			log.error('Failed to rename file to .zip extension')
			return nil, 'Failed to rename file to .zip extension'
		end
	end

	local pwsh_cmd = string.format(
		'Microsoft.PowerShell.Archive\\Expand-Archive -Path %q -DestinationPath %q -Force',
		source_file,
		self.dest
	)

	local cmd = string.format(
		--luacheck: ignore
		"%s -NoProfile -NonInteractive -Command \"$ProgressPreference = 'SilentlyContinue'; $ErrorActionPreference = 'Stop'; %s\"",
		pwsh,
		pwsh_cmd
	)
	log.debug('PowerShell command:', cmd)

	local result = vim.fn.system(cmd)
	local exit_code = vim.v.shell_error

	if exit_code ~= 0 then
		log.error('PowerShell extraction failed:', exit_code, result)
		return nil, string.format('PowerShell extraction failed (exit %d): %s', exit_code, result)
	end

	log.debug('PowerShell extraction completed')
	return true, nil
end

return PowerShellExtractor
