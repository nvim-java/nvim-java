local log = require('java.utils.log')
local async = require('java-core.utils.async').sync

local JavaCoreDap = require('java-core.dap')
local JavaCoreTestApi = require('java-core.api.test')

---@class JavaDap
---@field private client LspClient
---@field private dap JavaCoreDap
---@field private test_api JavaCoreTestApi
local M = {}

---@param args { client: LspClient }
---@return JavaDap
function M:new(args)
	local o = {
		client = args.client,
	}

	o.test_api = JavaCoreTestApi:new({
		client = args.client,
	})

	o.dap = JavaCoreDap:new({
		client = args.client,
	})

	setmetatable(o, self)
	self.__index = self
	return o
end

---Run the current test class
---@param config JavaCoreDapLauncherConfigOverridable
function M:execute_current_test_class(config)
	log.debug('running the current class')

	local buffer = vim.api.nvim_get_current_buf()

	return self.test_api:run_class_by_buffer(buffer, config)
end

function M:config_dap()
	log.debug('set dap adapter callback function')

	require('dap').adapters.java = function(callback)
		async(function()
			local adapter = self.dap:get_dap_adapter()
			callback(adapter --[[@as Adapter]])
		end).run()
	end

	local dap_config = self.dap:get_dap_config()

	log.debug('set dap config: ', dap_config)
	require('dap').configurations.java = dap_config
end

return M
