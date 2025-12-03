local class = require('java-core.utils.class')
local log = require('java-core.utils.log2')
local err_util = require('java-core.utils.errors')
local path = require('java-core.utils.path')

---@class java-core.PowerShell
---@field url string
---@field dest string
---@field retry_count number
---@field timeout number
local PowerShell = class()

---@class java-core.PowerShellOpts
---@field url string URL to download
---@field dest? string Destination path (optional, uses temp if not provided)
---@field retry_count? number Retry count (optional, defaults to 5)
---@field timeout? number Timeout in seconds (optional, defaults to 30)

---@param opts java-core.PowerShellOpts
function PowerShell:_init(opts)
	self.url = opts.url

	if not opts.dest then
		local filename = vim.fs.basename(opts.url)
		local tmp_dir = vim.fn.tempname()
		vim.fn.mkdir(tmp_dir, 'p')
		self.dest = path.join(tmp_dir, filename)
		log.debug('Using temp destination:', self.dest)
	else
		self.dest = opts.dest
		log.debug('Using provided destination:', self.dest)
	end

	self.retry_count = opts.retry_count or 5
	self.timeout = opts.timeout or 30
end

---Download file using PowerShell
---@return string # Path to downloaded file
function PowerShell:download()
	local pwsh = vim.fn.executable('pwsh') == 1 and 'pwsh' or 'powershell'
	log.debug('PowerShell downloading:', self.url, 'to', self.dest)
	log.debug('Using PowerShell binary:', pwsh)

	local pwsh_cmd = string.format(
		'iwr -TimeoutSec %d -UseBasicParsing -Method "GET" -Uri %q -OutFile %q;',
		self.timeout,
		self.url,
		self.dest
	)

	local cmd = string.format(
		-- luacheck: ignore
		"%s -NoProfile -NonInteractive -Command \"$ProgressPreference = 'SilentlyContinue'; $ErrorActionPreference = 'Stop'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; %s\"",
		pwsh,
		pwsh_cmd
	)
	log.debug('PowerShell command:', cmd)

	local result = vim.fn.system(cmd)
	local exit_code = vim.v.shell_error

	if exit_code ~= 0 then
		local err = string.format('PowerShell download failed (exit %d): %s', exit_code, result)
		err_util.throw(err)
	end

	log.debug('PowerShell download completed:', self.dest)
	return self.dest
end

return PowerShell
