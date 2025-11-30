local get_error_handler = require('java-core.utils.error_handler')
local log = require('java-core.utils.log2')

---Returns a error handler
---@param msg string messages to show in the error
---@return fun(err: any) # function that log and notify the error
return function(msg)
	return get_error_handler(msg, log)
end
