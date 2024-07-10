local get_jdtls = require('java.utils.jdtls2')
local JdtlsClient = require('java-core.ls.clients.jdtls-client')
local conf_utils = require('java.utils.config')
local notify = require('java-core.utils.notify')
local ui = require('java.utils.ui')
local async = require('java-core.utils.async').sync
local get_error_handler = require('java.handlers.error')

local M = {}

function M.change_runtime()
	local client = get_jdtls()

	---@type RuntimeOption[]
	local runtimes = conf_utils.get_property_from_conf(
		client.config,
		'settings.java.configuration.runtimes',
		{}
	)

	if #runtimes < 1 then
		notify.error(
			'No configured runtimes available'
				.. '\nRefer following link for instructions define available runtimes'
				.. '\nhttps://github.com/nvim-java/nvim-java?tab=readme-ov-file#clamp-how-to-use-jdk-xx-version'
		)
		return
	end

	local jdtls = JdtlsClient(client)

	async(function()
			local sel_runtime = ui.select(
				'Select Runtime',
				runtimes,
				function(runtime)
					return runtime.name .. '::' .. runtime.path
				end
			)

			for _, runtime in
				ipairs(client.config.settings.java.configuration.runtimes)
			do
				if sel_runtime.path == runtime.path then
					runtime.default = true
				else
					runtime.default = nil
				end
			end

			jdtls:workspace_did_change_configuration(client.config.settings)
		end)
		.catch(get_error_handler('Changing runtime failed'))
		.run()
end

return M
