local log = require('java.utils.log')
local async = require('java-core.utils.async').sync
local get_error_handler = require('java.handlers.error')
local jdtls = require('java.utils.jdtls')
local notify = require('java-core.utils.notify')

local DapSetup = require('java-dap.api.setup')

local M = {}
local RunnerApi = {}

--- @class RunnerApi
--- @field client LspClient
--- @field private dap JavaCoreDap
function RunnerApi:new(args)
	local o = {
		client = args.client,
	}

	o.dap = DapSetup(args.client)
	setmetatable(o, self)
	self.__index = self
	return o
end

function RunnerApi:get_config()
	local configs = self.dap:get_dap_config()
	log.debug('dap configs: ', configs)

	local config_names = {}
	local config_lookup = {}
	for _, config in ipairs(configs) do
		if config.projectName then
			table.insert(config_names, config.name)
			config_lookup[config.name] = config
		end
	end

	if #config_names == 0 then
		notify.warn('Dap config not found')
		return
	end

	if #config_names == 1 then
		return config_lookup[config_names[1]]
	end

	local selected_config = nil
	vim.ui.select(config_names, {
		prompt = 'Select the main class (modul -> mainClass)',
	}, function(choice)
		selected_config = config_lookup[choice]
	end)
	return selected_config
end

--- @param callback fun(cmd)
function RunnerApi:run_app(callback)
	local config = self:get_config()
	if not config then
		return
	end

	config.request = 'launch'
	local enrich_config = self.dap:enrich_config(config)
	local class_paths = table.concat(enrich_config.classPaths, ':')
	local main_class = enrich_config.mainClass
	local java_exec = enrich_config.javaExec

	local cmd = {
		java_exec,
		'-cp',
		class_paths,
		main_class,
	}

	callback(cmd)
end

--- @param callback fun(cmd)
function M.run_app(callback)
	return async(function()
			return RunnerApi:new(jdtls()):run_app(callback)
		end)
		.catch(get_error_handler('failed to run app'))
		.run()
end

M.RunnerApi = RunnerApi

return M
