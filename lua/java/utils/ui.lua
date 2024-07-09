local async = require('java-core.utils.async')
local await = async.wait
local notify = require('java-core.utils.notify')

local M = {}

---Async vim.ui.select function
---@generic T
---@param prompt string
---@param values T[]
---@param format_item fun(item: T): string
---@return T
function M.select(prompt, values, format_item)
	return await(function(callback)
		vim.ui.select(values, {
			prompt = prompt,
			format_item = format_item,
		}, callback)
	end)
end

function M.input(prompt)
	return await(function(callback)
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
