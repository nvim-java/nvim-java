local co = coroutine

local function __join(thunks)
	local len = #thunks
	local done = 0
	local acc = {}

	local thunk = function(step)
		if len == 0 then
			return step()
		end
		for i, tk in ipairs(thunks) do
			assert(type(tk) == 'function', 'thunk must be function')
			local callback = function(...)
				acc[i] = { ... }
				done = done + 1
				if done == len then
					step(unpack(acc))
				end
			end
			tk(callback)
		end
	end
	return thunk
end

---Waits for list of async calls to be completed
---@param defer fun(callback: fun(result: any))
---@return any[]
local function wait_all(defer)
	assert(type(defer) == 'table', 'type error :: expected table')
	return co.yield(__join(defer))
end

return wait_all
