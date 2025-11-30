local M = {}

function M.get_os()
	if vim.fn.has('mac') == 1 then
		return 'mac'
	elseif vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1 then
		return 'win'
	else
		return 'linux'
	end
end

---@return boolean
function M.is_arm()
	local arch = jit.arch
	return arch == 'arm' or arch == 'arm64' or arch == 'aarch64'
end

---@return 'arm'|'x86'
function M.get_arch()
	return M.is_arm() and 'arm' or 'x86'
end

---@return '32bit'|'64bit'
function M.get_bit_depth()
	local arch = jit.arch
	if arch == 'x64' or arch == 'arm64' or arch == 'aarch64' then
		return '64bit'
	end
	return '32bit'
end

---@return string
function M.get_config_suffix()
	local os = M.get_os()
	local suffix = 'config_' .. os

	if os ~= 'win' and M.is_arm() then
		suffix = suffix .. '_arm'
	end

	return suffix
end

return M
