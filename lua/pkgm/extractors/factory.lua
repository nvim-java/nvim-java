local system = require('java-core.utils.system')
local Unzip = require('pkgm.extractors.unzip')
local Tar = require('pkgm.extractors.tar')
local PowerShellExtractor = require('pkgm.extractors.powershell')
local Uncompressed = require('pkgm.extractors.uncompressed')
local log = require('java-core.utils.log2')
local err_util = require('java-core.utils.errors')

local M = {}

---Get appropriate extractor based on file extension
---@param opts table Extractor options (source, dest)
---@return table # Extractor instance
function M.get_extractor(opts)
	local source = opts.source
	local lower_source = source:lower()
	local os = system.get_os()
	log.debug('Getting extractor for:', source, 'on OS:', os)

	-- Check for zip files
	if lower_source:match('%.zip$') or lower_source:match('%.vsix$') then
		log.debug('Detected zip file')
		-- On Windows, prefer PowerShell
		if os == 'win' then
			if vim.fn.executable('pwsh') == 1 or vim.fn.executable('powershell') == 1 then
				log.debug('Using PowerShell extractor')
				return PowerShellExtractor(opts)
			end
		end

		-- Check for unzip on all platforms
		if vim.fn.executable('unzip') == 1 then
			log.debug('Using unzip extractor')
			return Unzip(opts)
		end

		-- Fallback to PowerShell on Windows if available
		if os == 'win' and (vim.fn.executable('pwsh') == 1 or vim.fn.executable('powershell') == 1) then
			log.debug('Using PowerShell extractor (fallback)')
			return PowerShellExtractor(opts)
		end

		local err = 'No zip extractor available (unzip or powershell not found)'
		err_util.throw(err)
	end

	-- Check for tar files
	if
		lower_source:match('%.tar$')
		or lower_source:match('%.tar%.gz$')
		or lower_source:match('%.tgz$')
		or lower_source:match('%.tar%.xz$')
		or lower_source:match('%.tar%.bz2$')
	then
		log.debug('Detected tar file')
		local tar_cmd = vim.fn.executable('gtar') == 1 and 'gtar' or 'tar'
		if vim.fn.executable(tar_cmd) == 1 then
			log.debug('Using tar extractor:', tar_cmd)
			return Tar(opts)
		else
			local err = 'tar not available'
			err_util.throw(err)
		end
	end

	-- Check for jar files
	if lower_source:match('%.jar$') then
		log.debug('Detected jar file')
		log.debug('Using uncompressed extractor')
		return Uncompressed(opts)
	end

	local err = string.format('Unsupported archive format: %s', source)
	err_util.throw(err)
end

return M
