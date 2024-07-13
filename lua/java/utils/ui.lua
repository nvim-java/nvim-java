local wait = require('async.waits.wait')
local notify = require('java-core.utils.notify')
local List = require('java-core.utils.list')

local M = {}

---Async vim.ui.select function
---@generic T
---@param prompt string
---@param values T[]
---@param format_item? fun(item: T): string
---@return T
function M.select(prompt, values, format_item)
	return wait(function(callback)
		vim.ui.select(values, {
			prompt = prompt,
			format_item = format_item,
		}, callback)
	end)
end

function M.multi_select(prompt, values, format_item)
	return wait(function(callback)
		local wrapped_items = List:new(values):map(function(item, index)
			return {
				index = index,
				is_selected = false,
				value = item,
			}
		end)

		local open_select

		open_select = function()
			vim.ui.select(wrapped_items, {
				prompt = prompt,
				format_item = function(item)
					local prefix = item.is_selected and '* ' or ''
					return prefix
						.. (format_item and format_item(item.value) or item.value)
				end,
			}, function(selected)
				if not selected then
					local selected_items = wrapped_items
						:filter(function(item)
							return item.is_selected
						end)
						:map(function(item)
							return item.value
						end)

					callback(#selected_items > 0 and selected_items or nil)
					return
				end

				wrapped_items[selected.index].is_selected =
					not wrapped_items[selected.index].is_selected

				open_select()
			end)
		end

		open_select()
	end)
end

function M.input(prompt)
	return wait(function(callback)
		vim.ui.input({
			prompt = prompt,
		}, callback)
	end)
end

---@param configs table
function M.select_from_dap_configs(configs)
	local config_names = {}
	local config_lookup = {}
	for _, config in ipairs(configs) do
		if config.projectName then
			local key = config.name
			if config.extra_args then
				key = key .. ' | ' .. config.extra_args
			end
			table.insert(config_names, key)
			config_lookup[key] = config
		end
	end

	if #config_names == 0 then
		notify.warn('Config not found')
		return
	end

	if #config_names == 1 then
		return config_lookup[config_names[1]]
	end

	local selected_config =
		M.select('Select the main class (modul -> mainClass)', config_names)
	return config_lookup[selected_config]
end

return M
