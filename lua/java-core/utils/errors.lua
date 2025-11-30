local notify = require('java-core.utils.notify')
local log = require('java-core.utils.log2')

local M = {}

---Notifies user, logs error, and throws error
---@param msg string error message
function M.throw(msg)
	notify.error(msg)
	log.error(msg)
	error(msg)
end

return M
