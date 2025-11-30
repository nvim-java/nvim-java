local co = coroutine

---Waits for async function to be completed
---@generic T
---@param defer fun(callback: fun(result: T))
---@return T
local function wait(defer)
	assert(type(defer) == 'function', 'type error :: expected func')
	return co.yield(defer)
end

return wait
