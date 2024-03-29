local async = require('java-core.utils.async').sync
local get_error_handler = require('java.handlers.error')
local class = require('java-core.utils.class')

local current_project_path = vim.fn.expand('%:p:h')
local config_path = vim.fn.stdpath('data') .. '/nvim-java-profiles.json'

--- @class Profile
--- @field vm_args string
--- @field prog_args string
--- @field name string
--- @field is_active boolean
local Profile = class()

--- @param vm_args string
--- @param prog_args string
--- @param name string
--- @param is_active boolean
function Profile:_init(vm_args, prog_args, name, is_active)
	self.vm_args = vm_args
	self.prog_args = prog_args
	self.name = name
	self.is_active = is_active or false
end

--- @return table
local function read_full_config()
	local file = io.open(config_path, 'r')
	if not file then
		return {}
	end
	local data = file:read('*a')
	file:close()
	local ok, config = pcall(vim.fn.json_decode, data)
	if not ok or not config then
		vim.notify('Failed to read config')
		return {}
	end
	return config
end

--- @return table<string, Profile>
local function load_current_project_profiles()
	local result = {}
	local current = read_full_config()[current_project_path] or {}
	for key, val in pairs(current) do
		result[key] = Profile(val.vm_args, val.prog_args, val.name, val.is_active)
	end
	return result
end

local M = {}

--- @type table<string, Profile>
local project_profiles = load_current_project_profiles()

local function save()
	return async(function()
			local full_config = read_full_config()
			full_config[current_project_path] = project_profiles
			local ok, json = pcall(vim.fn.json_encode, full_config)
			assert(ok, 'Failed to encode json')
			local file = io.open(config_path, 'w')
			assert(file, 'Failed to open file')
			file:write(json)
			file:close()
		end)
		.catch(get_error_handler('Failed to save profile'))
		.run()
end

--- @return Profile|nil
function M.get_active_profile()
	for _, profile in pairs(project_profiles) do
		if profile.is_active then
			return profile
		end
	end
	if #project_profiles > 0 then
		error('No active profile')
	end
end

--- @param profile_name string
--- @return Profile
function M.get_profile_by_name(profile_name)
	return project_profiles[profile_name]
end

--- @return table<string, Profile>
function M.get_all_profiles()
	return project_profiles
end

--- @param profile_name string
function M.set_active_profile(profile_name)
	for _, profile in pairs(project_profiles) do
		if profile.is_active then
			profile.is_active = false
			break
		end
	end
	project_profiles[profile_name].is_active = true
	save()
end

---  @param current_profile_name string|nil
---  @param new_profile Profile
function M.add_or_update_profile(new_profile, current_profile_name)
	assert(new_profile.name, 'Profile name is required')
	if current_profile_name then
		project_profiles[current_profile_name] = nil
	end
	assert(
		project_profiles[new_profile.name] == nil,
		"Profile with name '" .. new_profile.name .. "' already exists"
	)
	for _, profile in pairs(project_profiles) do
		profile.is_active = false
	end
	new_profile.is_active = true
	project_profiles[new_profile.name] = new_profile
	save()
end

--- @param profile_name string
function M.delete_profile(profile_name)
	project_profiles[profile_name] = nil
	save()
end

--- @type Profile
M.Profile = Profile

return M
