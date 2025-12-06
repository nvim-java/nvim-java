local notify = require('java-core.utils.notify')
local log = require('java-core.utils.log2')

local M = {}

---Notifies user, logs error, and throws error
---@param ... string error message
function M.throw(...)
	notify.error(...)
	log.error(...)
	error(...)
end

return M
