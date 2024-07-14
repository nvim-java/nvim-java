local wait = require('async.waits.wait')
local List = require('java-core.utils.list')

local M = {}

---Async vim.ui.select function
---@generic T
---@param prompt string
---@param values T[]
---@param format_item? fun(item: T): string
---@param opts? { return_one: boolean }
---@return T | nil
function M.select(prompt, values, format_item, opts)
	opts = opts or { prompt_single = false }

	return wait(function(callback)
		if not opts.prompt_single and #values == 1 then
			callback(values[1])
			return
		end

		vim.ui.select(values, {
			prompt = prompt,
			format_item = format_item,
		}, callback)
	end)
end

---Async vim.ui.select function
---@generic T
---@param prompt string
---@param values T[]
---@param format_item? fun(item: T): string
---@return T[] | nil
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

return M
