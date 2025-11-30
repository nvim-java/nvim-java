local wrap = require('async.wrap')
local co = coroutine

---Runs the given function
---@param func fun(): any
---@return { run: function, catch: fun(error_handler: fun(error: any)) }
local function runner(func)
	local m = {
		error_handler = nil,
	}

	local async_thunk_factory = wrap(function(handler, parent_handler_callback)
		assert(type(handler) == 'function', 'type error :: expected func')
		local thread = co.create(handler)
		local step = nil

		step = function(...)
			local ok, thunk = co.resume(thread, ...)

			-- when an error() is thrown after co-routine is resumed, obviously further
			-- processing stops, and resume returns ok(false) and thunk(error) returns
			-- the error message
			if not ok then
				if m.error_handler then
					m.error_handler(thunk)
					return
				end

				if parent_handler_callback then
					parent_handler_callback(thunk)
					return
				end

				error('unhandled error ' .. thunk)
			end

			assert(ok, thunk)
			if co.status(thread) == 'dead' then
				if parent_handler_callback then
					parent_handler_callback(thunk)
				end
			else
				assert(type(thunk) == 'function', 'type error :: expected func')
				thunk(step)
			end
		end

		step()

		return m
	end)

	m.run = async_thunk_factory(func)

	m.catch = function(error_handler)
		m.error_handler = error_handler
		return m
	end

	return m
end

return runner
