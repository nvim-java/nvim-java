---Make the given function a promise automatically assuming the callback
---function is the last argument
---@generic T
---@param func fun(..., callback: fun(result: T)): any
---@return fun(...): T
local function wrap(func)
	assert(type(func) == 'function', 'type error :: expected func')

	local factory = function(...)
		local params = { ... }
		local thunk = function(step)
			table.insert(params, step)
			return func(unpack(params))
		end
		return thunk
	end
	return factory
end

return wrap
