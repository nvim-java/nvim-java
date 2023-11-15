local log = require('java-core.utils.log')
local get_error_handler = require('java.handlers.error')

local Promise = require('java-core.utils.promise')
local JavaCoreDap = require('java-core.dap')
local JavaCoreTestHelper = require('java-core.ls.helpers.test-helper')

---@class JavaDap
---@field client LSPClient
---@field test_helper JavaCoreTestHelper
---@field dap_helper JavaCoreDap
local M = {}

---@param args { client: LSPClient }
---@return JavaDap
function M:new(args)
	local o = {
		client = args.client,
	}

	o.test_helper = JavaCoreTestHelper:new({
		client = args.client,
	})

	o.dap_helper = JavaCoreDap:new({
		client = args.client,
	})

	setmetatable(o, self)
	self.__index = self
	return o
end

---Run the current test class
---@param config? JavaTestLauncherConfigOverridable
function M:execute_current_test_class(config)
	log.info('running the current class')

	local buffer = vim.api.nvim_get_current_buf()

	return self.test_helper
		:get_test_class_by_buffer(buffer)
		:thenCall(function(classes)
			return self.test_helper:run_test(classes, config)
		end)
		:catch(get_error_handler('failed to run current test class'))
end

function M:config_dap()
	return Promise.resolve()
		:thenCall(function()
			log.debug('set dap adapter callback function')

			-- setting java adapter
			require('dap').adapters.java = function(callback)
				self.dap_helper
					:get_dap_adapter()
					:thenCall(callback)
					:catch(get_error_handler('failed to set DAP adapter'))
			end

			-- setting java config
			return self.dap_helper:get_dap_config()
		end)
		:thenCall(function(dap_config)
			log.debug('set dap config: ', dap_config)
			require('dap').configurations.java = dap_config
		end)
		:catch(get_error_handler('failed to set DAP configuration'))
end

return M
