local JavaDap = require('java.dap')

local log = require('java.utils.log')
local get_error_handler = require('java.handlers.error')
local jdtls = require('java.utils.jdtls')
local async = require('java-core.utils.async').sync

local M = {}

---Setup dap config & adapter on jdtls attach event

function M.run_current_test_class()
	log.info('run current test class')

	return async(function()
			return JavaDap:new(jdtls()):execute_current_test_class({ noDebug = true })
		end)
		.catch(get_error_handler('failed to run the current test class'))
		.run()
end

function M.debug_current_test_class()
	log.info('debug current test class')

	return async(function()
			JavaDap:new(jdtls()):execute_current_test_class({})
		end)
		.catch(get_error_handler('failed to debug the current test class'))
		.run()
end

function M.debug_current_method()
	log.info('debug current test method')

	return async(function()
			return JavaDap:new(jdtls()):execute_current_test_method()
		end)
		.catch(get_error_handler('failed to run the current test method'))
		.run()
end

function M.run_current_method()
	log.info('run current test method')

	return async(function()
			return JavaDap:new(jdtls())
				:execute_current_test_method({ noDebug = true })
		end)
		.catch(get_error_handler('failed to run the current test method'))
		.run()
end

function M.config_dap()
	log.info('configuring dap')

	return async(function()
			JavaDap:new(jdtls()):config_dap()
		end)
		.catch(get_error_handler('dap configuration failed'))
		.run()
end

return M
