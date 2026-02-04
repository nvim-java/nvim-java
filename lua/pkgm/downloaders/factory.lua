local system = require('java-core.utils.system')
local Curl = require('pkgm.downloaders.curl')
local Wget = require('pkgm.downloaders.wget')
local PowerShell = require('pkgm.downloaders.powershell')
local log = require('java-core.utils.log2')
local err_util = require('java-core.utils.errors')

local M = {}

---Get appropriate downloader based on platform and binary availability
---@param opts table Downloader options (url, dest, retry_count, timeout)
---@return table # Downloader instance
function M.get_downloader(opts)
	local os = system.get_os()
	log.debug('Getting downloader for OS:', os)

	-- On Windows, prefer PowerShell
	if os == 'win' then
		if vim.fn.executable('pwsh') == 1 or vim.fn.executable('powershell') == 1 then
			log.debug('Using PowerShell downloader')
			return PowerShell(opts)
		end
	end

	-- Check for wget on all platforms
	if vim.fn.executable('wget') == 1 then
		log.debug('Using wget downloader')
		return Wget(opts)
	end

	-- Check for curl on all platforms
	if vim.fn.executable('curl') == 1 then
		log.debug('Using curl downloader')
		return Curl(opts)
	end

	-- On Windows, fallback to PowerShell if available
	if os == 'win' and (vim.fn.executable('pwsh') == 1 or vim.fn.executable('powershell') == 1) then
		log.debug('Using PowerShell downloader (fallback)')
		return PowerShell(opts)
	end

	local err = 'No downloader available (wget or powershell not found)'
	err_util.throw(err)
end

return M
