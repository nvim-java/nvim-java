local spy = require('luassert.spy')

describe('profile_config', function()
	it('as', function()
		local spy_fn = spy.on(vim.fn, 'expand')
		local config = require('java.api.profile_config').config

		config.read_config = function()
			return {}
		end
		assert.spy(spy_fn).was_called_with('%:p:h')
		assert.same(config.profiles, {})
	end)
end)

-- TODO
