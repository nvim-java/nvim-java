local co = coroutine

---Waits for async function to be completed but considers first parameter as
---error
---@generic T
---@param defer fun(callback: fun(result: T))
---@return T
local function wait(defer)
	assert(type(defer) == 'function', 'type error :: expected func')

	local err, value = co.yield(defer)

	if err then
		error(err)
	end

	return value
end

return wait
