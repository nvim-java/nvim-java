local runner = require('async.runner')

local M = {}

---@param params nvim.CodeActionParamsResponse
function M.generate_constructor(params)
	local instance = require('java.utils.instance_factory')
	local get_error_handler = require('java.handlers.error')
	local ui = require('java.utils.ui')

	return runner(function()
			local jdtls = instance.jdtls_client()
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

---@param params nvim.CodeActionParamsResponse
function M.generate_to_string(params)
	local instance = require('java.utils.instance_factory')
	local get_error_handler = require('java.handlers.error')
	local ui = require('java.utils.ui')

	runner(function()
			local jdtls = instance.jdtls_client()
			local status = jdtls:java_check_to_string_status(params.params)

			if status.exists then
				local prompt = string.format(
					'Method "toString()" already exists in the Class %s. Do you want to replace the implementation?',
					status.type
				)
				local choice = ui.select(prompt, { 'Replace', 'Cancel' })

				if choice ~= 'Replace' then
					return
				end
			end

			local fields = ui.multi_select(
				'Select the fields to include in the toString() method.',
				status.fields,
				function(field)
					return field.name
				end
			)

			if not fields then
				return
			end

			local edit = jdtls:java_generate_to_string({
				context = params.params,
				fields = fields,
			})

			vim.lsp.util.apply_workspace_edit(edit, 'utf-8')
		end)
		.catch(get_error_handler('Generating to string failed'))
		.run()
end

return M
