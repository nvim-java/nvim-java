local M = {}

---@alias java-core.LogLevel 'trace'|'debug'|'info'|'warn'|'error'|'fatal'

---@class java-core.Log2Config
---@field use_console boolean Enable console logging
---@field use_file boolean Enable file logging
---@field level java-core.LogLevel Minimum log level to display
---@field log_file string Path to log file
---@field max_lines number Maximum lines to keep in log file
---@field show_location boolean Show file location in log messages

---@class java-core.PartialLog2Config
---@field use_console? boolean Enable console logging
---@field use_file? boolean Enable file logging
---@field level? java-core.LogLevel Minimum log level to display
---@field log_file? string Path to log file
---@field max_lines? number Maximum lines to keep in log file
---@field show_location? boolean Show file location in log messages

---@type java-core.Log2Config
local default_config = {
	use_console = false,
	use_file = true,
	level = 'info',
	log_file = vim.fn.stdpath('log') .. '/nvim-java.log',
	max_lines = 100,
	show_location = false,
}

---@type java-core.Log2Config
local config = vim.deepcopy(default_config)

local log_levels = {
	trace = 1,
	debug = 2,
	info = 3,
	warn = 4,
	error = 5,
	fatal = 6,
}

local highlights = {
	trace = 'Comment',
	debug = 'Debug',
	info = 'DiagnosticInfo',
	warn = 'DiagnosticWarn',
	error = 'DiagnosticError',
	fatal = 'ErrorMsg',
}

---@param user_config? java-core.PartialLog2Config
function M.setup(user_config)
	config = vim.tbl_deep_extend('force', config, user_config or {})
end

--- Write message to log file with line limit
---@param msg string
---@private
local function write_to_file(msg)
	local log_file = config.log_file
	local lines = {}

	local file = io.open(log_file, 'r')
	if file then
		for line in file:lines() do
			table.insert(lines, line)
		end
		file:close()
	end

	table.insert(lines, msg)

	while #lines > config.max_lines do
		table.remove(lines, 1)
	end

	file = io.open(log_file, 'w')
	if file then
		for _, line in ipairs(lines) do
			file:write(line .. '\n')
		end
		file:close()
	end
end

--- Log a message
---@param level java-core.LogLevel
---@param ... any
local function log(level, ...)
	if log_levels[level] < log_levels[config.level] then
		return
	end

	local logs = {}

	for _, v in ipairs({ ... }) do
		table.insert(logs, vim.inspect(v))
	end

	local location = ''
	if config.show_location then
		local info = debug.getinfo(3, 'Sl')
		if info then
			local file = info.short_src or info.source or 'unknown'
			local line = info.currentline or 0
			location = '[' .. file .. ':' .. line .. ']'
		end
	end

	local msg = level:upper() .. (location ~= '' and '::' .. location or '') .. '::' .. table.concat(logs, '::')

	if config.use_console then
		local hl = highlights[level] or 'Normal'
		vim.api.nvim_echo({ { msg, hl } }, true, {})
	end

	if config.use_file then
		write_to_file(msg)
	end
end

function M.info(...)
	log('info', ...)
end

function M.debug(...)
	log('debug', ...)
end

function M.fatal(...)
	log('fatal', ...)
end

function M.error(...)
	log('error', ...)
end

function M.trace(...)
	log('trace', ...)
end

function M.warn(...)
	log('warn', ...)
end

return M
