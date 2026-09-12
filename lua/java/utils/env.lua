local M = {}

---@param path string
---@return boolean
local function is_absolute_path(path)
	return vim.startswith(path, '/')
		or path:match('^%a:[/\\]') ~= nil
		or vim.startswith(path, '\\\\')
end

---@param path string
---@param base_dir string|nil
---@return string
local function resolve_path(path, base_dir)
	local expanded = vim.fn.expand(path)

	if is_absolute_path(expanded) then
		return vim.fn.fnamemodify(expanded, ':p')
	end

	if base_dir and vim.trim(base_dir) ~= '' then
		return vim.fn.fnamemodify(base_dir .. '/' .. expanded, ':p')
	end

	return vim.fn.fnamemodify(expanded, ':p')
end

---@param value string
---@return string
local function trim(value)
	return vim.trim(value or '')
end

---@param value string
---@return string
local function normalize_value(value)
	local trimmed = trim(value)
	local quote = trimmed:sub(1, 1)

	if (quote == '"' or quote == "'") and trimmed:sub(-1) == quote then
		return trimmed:sub(2, -2)
	end

	return trimmed
end

---@param line string
---@return string|nil
---@return string|nil
function M.parse_line(line)
	local trimmed = trim(line)

	if trimmed == '' or trimmed:sub(1, 1) == '#' then
		return nil, nil
	end

	trimmed = trimmed:gsub('^export%s+', '')
	local key, value = trimmed:match('^([%w_.%-]+)%s*=%s*(.*)$')

	if not key then
		return nil, 'Expected KEY=VALUE'
	end

	return key, normalize_value(value)
end

---@param lines string[]
---@return table<string, string>
---@return string|nil
function M.parse_lines(lines)
	local env = {}

	for index, line in ipairs(lines) do
		local key, value_or_error = M.parse_line(line)

		if key == nil and value_or_error then
			return {}, string.format('Line %s: %s', index, value_or_error)
		end

		if key then
			env[key] = value_or_error
		end
	end

	return env, nil
end

---@param value string
---@return table<string, string>
---@return string|nil
function M.parse_string(value)
	return M.parse_lines(vim.split(value or '', '\n', { plain = true }))
end

---@param env table<string, string>|nil
---@return string
function M.stringify(env)
	if not env or vim.tbl_isempty(env) then
		return ''
	end

	local keys = vim.tbl_keys(env)
	table.sort(keys)

	local lines = {}
	for _, key in ipairs(keys) do
		table.insert(lines, string.format('%s=%s', key, env[key]))
	end

	return table.concat(lines, '\n')
end

---@param env_file string|nil
---@param base_dir string|nil
---@return table<string, string>
---@return string|nil
function M.read_file(env_file, base_dir)
	local path = trim(env_file)

	if path == '' then
		return {}, nil
	end

	path = resolve_path(path, base_dir)

	local file = io.open(path, 'r')
	if not file then
		return {}, 'Failed to open env file: ' .. path
	end

	local data = file:read('*a')
	file:close()

	local env, err = M.parse_string(data)
	if err then
		return {}, string.format('Failed to parse env file %s: %s', path, err)
	end

	return env, nil
end

---@param profile Profile
---@param base_dir string|nil
---@return table<string, string>
---@return string|nil
function M.load_profile_env(profile, base_dir)
	local env_from_file, err = M.read_file(profile.env_file, base_dir)
	if err then
		return {}, err
	end

	return vim.tbl_extend('force', env_from_file, profile.env or {}), nil
end

return M
