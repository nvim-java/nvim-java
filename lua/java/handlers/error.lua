local notify = require('java-core.utils.notify')
local log = require('java.utils.log')

local function table_tostring(tbl)
	local str = ''
	for _, v in ipairs(tbl) do
		str = str .. '\n' .. tostring(v)
	end

	return str
end

---Returns a error handler
---@param msg string messages to show in the error
---@return fun(err: any) # function that log and notify the error
local function get_error_handler(msg)
	return function(err)
		local trace = debug.traceback()

		local log_obj = { msg }
		table.insert(log_obj, err)
		table.insert(log_obj, trace)

		local log_str = table_tostring(log_obj)

		log.error(log_str)
		notify.error(log_str)
		error(log_str)
	end
end

return get_error_handler
