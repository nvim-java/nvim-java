local M = {}

---@param params nvim.CodeActionParamsResponse
function M.generate_constructor(params)
	local JdtlsClient = require('java-core.ls.clients.jdtls-client')
	local async = require('java-core.utils.async').sync
	local get_client = require('java.utils.jdtls2')
	local get_error_handler = require('java.handlers.error')
	local ui = require('java.utils.ui')

	return async(function()
			local jdtls = JdtlsClient(get_client())
			local status = jdtls:java_check_constructors_status(params.params)

			if not status or not status.constructors then
				return
			end

			local selected_constructor = ui.select(
				'Select super class constructor(s).',
				status.constructors,
				function(constructor)
					return string.format(
						'%s %s',
						constructor.name,
						table.concat(constructor.parameters, ', ')
					)
				end
			)

			if not selected_constructor then
				return
			end

			local selected_fields = ui.multi_select(
				'Select Fields:',
				status.fields,
				function(field)
					return field.name
				end
			)

			local edit = jdtls:java_generate_constructor({
				context = params.params,
				constructors = { selected_constructor },
				fields = selected_fields or {},
			})

			vim.lsp.util.apply_workspace_edit(edit, 'utf-8')
		end)
		.catch(get_error_handler('Generating constructor failed'))
		.run()
end

return M
