local log = require('java.utils.log')
local get_error_handler = require('java.handlers.error')

local Promise = require('java-core.utils.promise')
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
	log.info('running the current class')

	local buffer = vim.api.nvim_get_current_buf()

	return self.test_api
		:run_class_by_buffer(buffer, config)
		:catch(get_error_handler('failed to run current test class'))
end

function M:config_dap()
	return Promise.resolve()
		:thenCall(function()
			log.debug('set dap adapter callback function')

			-- setting java adapter
			require('dap').adapters.java = function(callback)
				self.dap
					:get_dap_adapter()
					:thenCall(callback)
					:catch(get_error_handler('failed to set DAP adapter'))
			end

			-- setting java config
			return self.dap:get_dap_config()
		end)
		:thenCall(function(dap_config)
			log.debug('set dap config: ', dap_config)
			require('dap').configurations.java = dap_config
		end)
		:catch(get_error_handler('failed to set DAP configuration'))
end

return M
