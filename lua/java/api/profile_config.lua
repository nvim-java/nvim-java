local log = require('java.utils.log')
local async = require('java-core.utils.async').sync
local get_error_handler = require('java.handlers.error')

local config_path = vim.fn.stdpath('data') .. '/nvim-java-profiles.json'
local current_project_path = vim.fn.expand('%:p:h')

--- @class ProjectConfig
--- @field profiles table
local ProjectConfig = {}
function ProjectConfig:new()
	local o = {
		current_project_path = vim.fn.expand('%:p:h'),
	}
	o.profiles = ProjectConfig.read_config()

	setmetatable(o, self)
	self.__index = self
	return o
end

function ProjectConfig:get_active_profile()
	log.error('profiles', vim.inspect(self.profiles))
	for key, _ in pairs(self.profiles) do
		if self.profiles[key].is_active then
			return self.profiles[key]
		end
	end
end

function ProjectConfig._read_full_config()
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

function ProjectConfig.read_config()
	return ProjectConfig._read_full_config()[current_project_path] or {}
end

function ProjectConfig:save()
	return async(function()
			local full_config = self:_read_full_config()
			full_config[current_project_path] = self.profiles
			local ok, json = pcall(vim.fn.json_encode, full_config)
			assert(ok, 'Failed to encode json')
			local file = io.open(config_path, 'w')
			assert(file, 'Failed to open file')
			file:write(json)
			file:close()
		end)
		.catch(get_error_handler('dap configuration failed'))
		.run()
end

local M = {}
M.config = ProjectConfig:new()

return M
