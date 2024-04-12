local async = require('java-core.utils.async').sync
local get_error_handler = require('java.handlers.error')
local class = require('java-core.utils.class')

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

-- palin config structure
-- {
-- 	"roo_dir" : {
--  	"mod1 -> main_class" : [
--  		{
--  			"vm_args": "-Xmx1024m",
--  			"prog_args": "arg1 arg2",
--  			"name": "profile_name1",
--  			"is_active": true
--  		},
--  		{
--  			"vm_args": "-Xmx1024m",
--  			"prog_args": "arg1 arg2",
--  			"name": "profile_name2",
--  			"is_active": false
--  		}
--  	],
--  	"mod2 -> main_class" : [
--  		...
--  	]
--  }
-- }
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

local M = {}

-- loaded profiles
-- {
-- 	['mod1 -> dap_config_name'] = {
-- 		profile_name1 = {
-- 			vm_args = '-Xmx1024m',
-- 			prog_args = 'arg1 arg2',
-- 			name = 'profile_name1',
-- 			is_active = true,
-- 		},
-- 		profile_name2 = {
-- 			vm_args = '-Xmx1024m',
-- 			prog_args = 'arg1 arg2',
-- 			name = 'profile_name2',
-- 			is_active = false,
-- 		},
-- 	},
-- 	['mod2 -> dap_config_name'] = {
-- 		....
-- 	},
-- }
--- @return table<string, table<string, Profile>>
function M.load_current_project_profiles()
	local result = {}
	local current = read_full_config()[M.current_project_path] or {}
	for dap_config_name, dap_config_name_val in pairs(current) do
		result[dap_config_name] = {}
		for _, profile in pairs(dap_config_name_val) do
			result[dap_config_name][profile.name] = Profile(
				profile.vm_args,
				profile.prog_args,
				profile.name,
				profile.is_active
			)
		end
	end
	return result
end

function M.save()
	return async(function()
			local full_config = read_full_config()
			local updated_profiles = {}
			for dap_config_name, val in pairs(M.project_profiles) do
				updated_profiles[dap_config_name] = {}
				for _, profile in pairs(val) do
					table.insert(updated_profiles[dap_config_name], profile)
				end
			end
			full_config[M.current_project_path] = updated_profiles
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
--- @param dap_config_name string
--- @return Profile|nil
function M.get_active_profile(dap_config_name)
	if M.project_profiles[dap_config_name] == nil then
		return nil
	end
	local number_of_profiles = 0
	for _, profile in pairs(M.project_profiles[dap_config_name]) do
		number_of_profiles = number_of_profiles + 1
		if profile.is_active then
			return profile
		end
	end
	if number_of_profiles > 0 then
		error('No active profile')
	end
end

--- @param dap_config_name string
--- @param profile_name string
--- @return Profile|nil
function M.get_profile(profile_name, dap_config_name)
	if M.project_profiles[dap_config_name] == nil then
		return nil
	end
	return M.project_profiles[dap_config_name][profile_name]
end

--- @param dap_config_name string
--- @return table<string, Profile>
function M.get_all_profiles(dap_config_name)
	return M.project_profiles[dap_config_name] or {}
end
--- @param dap_config_name string
--- @param profile_name string
function M.set_active_profile(profile_name, dap_config_name)
	if not M.__has_profile(profile_name, dap_config_name) then
		return
	end

	for _, profile in pairs(M.project_profiles[dap_config_name]) do
		if profile.is_active then
			profile.is_active = false
			break
		end
	end

	M.project_profiles[dap_config_name][profile_name].is_active = true
	M.save()
end

--- @param dap_config_name string
--- @param current_profile_name string|nil
--- @param new_profile Profile
function M.add_or_update_profile(
	new_profile,
	current_profile_name,
	dap_config_name
)
	assert(new_profile.name, 'Profile name is required')
	if current_profile_name then
		M.project_profiles[dap_config_name][current_profile_name] = nil
	end
	assert(
		M.get_profile(new_profile.name, dap_config_name) == nil,
		"Profile with name '" .. new_profile.name .. "' already exists"
	)

	if M.project_profiles[dap_config_name] == nil then
		M.project_profiles[dap_config_name] = {}
	else
		for _, profile in pairs(M.project_profiles[dap_config_name]) do
			profile.is_active = false
		end
	end

	new_profile.is_active = true
	M.project_profiles[dap_config_name][new_profile.name] = new_profile
	M.save()
end

--- @param dap_config_name string
--- @param profile_name string
function M.delete_profile(profile_name, dap_config_name)
	if not M.__has_profile(profile_name, dap_config_name) then
		return
	end

	M.project_profiles[dap_config_name][profile_name] = nil
	M.save()
end

---Returns true if a profile exists by given name
---@param profile_name string
---@param dap_config_name string
function M.__has_profile(profile_name, dap_config_name)
	if M.project_profiles[dap_config_name][profile_name] then
		return true
	end

	return false
end

--- @type Profile
M.Profile = Profile

M.setup = function()
	async(function()
			M.current_project_path = vim.fn.getcwd()
			M.project_profiles = M.load_current_project_profiles()
		end)
		.catch(get_error_handler('Failed to read profile config'))
		.run()
end

return M
