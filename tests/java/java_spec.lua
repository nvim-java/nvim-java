local plugin = require('java')
local mock = require('luassert.mock')

describe('setup', function()
	it('setup function', function()
		assert('setup function is available', plugin.setup)
	end)

	describe('check runner function available:', function()
		local mock_runner = mock(plugin.runner, true)

		it('run_app', function()
			mock_runner.run_app.returns({})

			assert.same(plugin.runner.run_app(), {})
		end)
	end)
end)
