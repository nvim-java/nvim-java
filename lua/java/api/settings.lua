local jdtls = require('java.utils.jdtls')
local notify = require('java-core.utils.notify')
local JdtlsClient = require('java-core.ls.clients.jdtls-client')

local M = {}

function M.change_runtime()
	local client = jdtls().client
	local jdtls_client = JdtlsClient(client)

	local settings = vim.tbl_deep_extend('keep', client.config.settings, {
		java = {
			configuration = {
				runtimes = {},
			},
		},
	})

	if #settings.java.configuration.runtimes == 0 then
		notify.warn(
			"You don't have any registered runtimes to select from! Please configure runtimes first"
		)
		return
	end

	vim.ui.select(settings.java.configuration.runtimes, {
		format_item = function(runtime)
			return runtime.name
		end,
	}, function(selected_runtime)
		if not selected_runtime then
			return
		end

		for _, runtime in ipairs(settings.java.configuration.runtimes) do
			runtime.default = false

			if
				selected_runtime.name == runtime.name
				and selected_runtime.path == runtime.path
			then
				runtime.default = true
			end
		end

		jdtls_client:did_change_configuration({ settings = settings })
	end)
end

return M
