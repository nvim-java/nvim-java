local path = require('java-core.utils.path')
local class = require('java-core.utils.class')
local log = require('java-core.utils.log2')

---@class java-core.Wget
---@field url string
---@field dest string
---@field retry_count number
---@field timeout number
local Wget = class()

---@class java-core.WgetOpts
---@field url string URL to download
---@field dest? string Destination path (optional, uses temp if not provided)
---@field retry_count? number Retry count (optional, defaults to 5)
---@field timeout? number Timeout in seconds (optional, defaults to 30)

---@param opts java-core.WgetOpts
function Wget:_init(opts)
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

---Download file using wget
---@param on_finished fun(file_path: string|nil, err: string|nil)
function Wget:download(on_finished)
	log.debug('wget downloading:', self.url, 'to', self.dest)
	local cmd = {
		'wget',
		'-t',
		self.retry_count,
		'-T',
		self.timeout,
		'-O',
		self.dest,
		self.url,
	}
	log.debug('wget command:', cmd)

	vim.system(cmd, { text = true }, function(out)
		local result = out.stderr
		local exit_code = out.code

		if exit_code ~= 0 then
			log.error('wget failed:', exit_code, result)
			on_finished(nil, string.format('wget failed (exit %d): %s', exit_code, result))
			return
		end

		log.debug('wget download completed:', self.dest)
		on_finished(self.dest, nil)
	end)
end

return Wget
