local mock = require('luassert.mock')
local Profile = require('java.api.profile_config').Profile
local spy = require('luassert.spy')

describe('java.api.profile_config', function()
	local mock_fn = {}
	local mock_io = {}
	local file_mock = {
		read = function(_, readmode)
			assert(readmode == '*a')
			return '{ "test": "test" }'
		end,
		close = function() end,
	}

	before_each(function()
		package.loaded['java.api.profile_config'] = nil
		mock_io = mock(io, true)
		mock_fn = mock(vim.fn, true)
		mock_fn.stdpath = function()
			return 'config_path'
		end

		mock_fn.expand = function()
			return 'project_path'
		end
	end)

	after_each(function()
		mock.revert(mock_fn)
		mock.revert(mock_io)
	end)

	describe('read_config', function()
		it('when no config file', function()
			mock_io.open = function()
				return nil
			end

			local profile_config = require('java.api.profile_config')

			assert.same(profile_config.get_all_profiles(), {})
		end)

		it('when config cannot be decoded', function()
			mock_io.open = function()
				return file_mock
			end

			mock_fn.json_decode = function()
				return '{'
			end

			local profile_config = require('java.api.profile_config')
			assert.same(profile_config.get_all_profiles(), {})
		end)

		it('successfully', function()
			mock_io.open = function(config_path, mode)
				assert(config_path == 'config_path/nvim-java-profiles.json')
				assert(mode == 'r')
				return file_mock
			end

			local expected_profile = {
				test = {
					vm_args = 'vm_args',
					prog_args = 'prog_args',
					name = 'name',
					is_active = true,
				},
			}
			mock_fn.json_decode = function(data)
				assert(data == '{ "test": "test" }')
				return { project_path = expected_profile }
			end

			local profile_config = require('java.api.profile_config')
			assert.same(profile_config.get_all_profiles(), expected_profile)
		end)
	end)

	describe('add_or_update_profile', function()
		it('when updating profile', function()
			-- setup
			-- local closed_called = 0
			local expected_profile_table = {
				name = {
					vm_args = 'vm_args',
					prog_args = 'prog_args',
					name = 'name',
					is_active = true,
				},
			}
			local current_profile_table = {
				old_name = {
					vm_args = 'old_vm_args',
					prog_args = 'old_prog_args',
					name = 'old_name',
					is_active = true,
				},
			}
			local input_profile = Profile('vm_args', 'prog_args', 'name', true)

			-- mocks/verify mocks calls with expected values
			mock_io.open = function()
				return file_mock
			end

			file_mock.write = function(_, json)
				assert(json == 'json')
			end

			mock_fn.json_encode = function(data)
				assert.same(data, { project_path = expected_profile_table })
				return 'json'
			end
			mock_fn.json_decode = function()
				return { project_path = current_profile_table }
			end

			local spy_close = spy.on(file_mock, 'close')

			-- call the function
			local profile_config = require('java.api.profile_config')
			profile_config.add_or_update_profile(input_profile, 'old_name')

			--- verify
			assert.same(profile_config.get_all_profiles(), expected_profile_table)
			assert.spy(spy_close).was_called(3) -- init, full_config, save
		end)

		it('when add new profile (set activate automatically)', function()
			-- setup
			local current_profile_table = {
				name1 = {
					vm_args = 'vm_args1',
					prog_args = 'prog_args1',
					name = 'name1',
					is_active = true, -- now this profile is active
				},
			}
			local expected_profile_table = vim.deepcopy(current_profile_table)
			expected_profile_table.name2 = {
				vm_args = 'vm_args2',
				prog_args = 'prog_args2',
				name = 'name2',
				is_active = true, -- expected this profile to be active
			}
			expected_profile_table.name1.is_active = false

			local input_profile = Profile('vm_args2', 'prog_args2', 'name2')

			-- mocks/verify mocks calls with expected values
			mock_io.open = function()
				return file_mock
			end

			file_mock.write = function(_, json)
				assert(json == 'json')
			end

			mock_fn.json_encode = function(data)
				assert.same(data, { project_path = expected_profile_table })
				return 'json'
			end
			mock_fn.json_decode = function()
				return { project_path = current_profile_table }
			end
			local spy_close = spy.on(file_mock, 'close')

			-- call the function
			local profile_config = require('java.api.profile_config')
			profile_config.add_or_update_profile(input_profile, nil)

			--- verify
			assert.same(profile_config.get_all_profiles(), expected_profile_table)
			assert.spy(spy_close).was_called(3) -- init, full_config, save
		end)

		it('when profile already exists', function()
			-- setup
			local current_profile_table = {
				name1 = {
					vm_args = 'vm_args1',
					prog_args = 'prog_args1',
					name = 'name1',
					is_active = true,
				},
			}
			local input_profile = Profile('vm_args1', 'prog_args1', 'name1')

			-- mocks/verify mocks calls with expected values
			mock_io.open = function()
				return file_mock
			end

			mock_fn.json_decode = function()
				return { project_path = current_profile_table }
			end

			-- call the function
			local profile_config = require('java.api.profile_config')
			assert.has.error(function()
				profile_config.add_or_update_profile(input_profile, nil)
			end, "Profile with name 'name1' already exists")
		end)

		it('when profile name is required', function()
			-- setup
			local input_profile = Profile('vm_args', 'prog_args', nil)

			-- call the function
			local profile_config = require('java.api.profile_config')
			assert.has.error(function()
				profile_config.add_or_update_profile(input_profile, nil)
			end, 'Profile name is required')
		end)
	end)

	it('set_active_profile', function()
		-- setup

		local current_profile_table = {
			name1 = {
				vm_args = 'vm_args1',
				prog_args = 'prog_args1',
				name = 'name1',
				is_active = true, -- now this profile is active
			},
			name2 = {
				vm_args = 'vm_args2',
				prog_args = 'prog_args2',
				name = 'name2',
				is_active = false,
			},
		}

		local expected_profile_table = vim.deepcopy(current_profile_table)
		-- switch active profile
		expected_profile_table.name2.is_active = true
		expected_profile_table.name1.is_active = false

		-- mocks/verify mocks calls with expected values
		mock_io.open = function()
			return file_mock
		end

		file_mock.write = function(_, json)
			assert(json == 'json')
		end

		mock_fn.json_encode = function(data)
			assert.same(data, { project_path = expected_profile_table })
			return 'json'
		end
		mock_fn.json_decode = function()
			return { project_path = current_profile_table }
		end
		local spy_close = spy.on(file_mock, 'close')

		-- call the function
		local profile_config = require('java.api.profile_config')
		profile_config.set_active_profile('name2')

		--- verify
		assert.same(profile_config.get_all_profiles(), expected_profile_table)
		assert.spy(spy_close).was_called(3) -- init, full_config, save
	end)

	it('get_profile_by_name', function()
		-- setup
		local current_profile_table = {
			name1 = {
				vm_args = 'vm_args1',
				prog_args = 'prog_args1',
				name = 'name1',
				is_active = true,
			},
		}

		-- mocks/verify mocks calls with expected values
		mock_io.open = function()
			return file_mock
		end

		mock_fn.json_decode = function()
			return { project_path = current_profile_table }
		end

		-- call the function
		local profile_config = require('java.api.profile_config')
		local profile = profile_config.get_profile_by_name('name1')

		--- verify
		assert.same(profile, Profile('vm_args1', 'prog_args1', 'name1', true))
	end)

	describe('get_active_profile', function()
		-- mocks/verify mocks calls with expected values
		local current_profile_table = {
			name1 = {
				vm_args = 'vm_args1',
				prog_args = 'prog_args1',
				name = 'name1',
				is_active = true,
			},
			name2 = {
				vm_args = 'vm_args2',
				prog_args = 'prog_args2',
				name = 'name2',
				is_active = false,
			},
		}
		it('succesfully', function()
			-- setup
			mock_io.open = function()
				return file_mock
			end

			mock_fn.json_decode = function()
				return { project_path = current_profile_table }
			end

			-- call the function
			local profile_config = require('java.api.profile_config')
			local profile = profile_config.get_active_profile()
			--- verify
			assert.same(profile, Profile('vm_args1', 'prog_args1', 'name1', true))
		end)

		it('when #projec_profiles == 0', function()
			mock_io.open = function()
				return file_mock
			end
			mock_fn.json_decode = function()
				return { project_path = {} }
			end
			local profile_config = require('java.api.profile_config')
			local profile = profile_config.get_active_profile()
			assert(profile == nil)
		end)

		it('when #projec_profiles > 0', function()
			mock_io.open = function()
				return file_mock
			end
			mock_fn.json_decode = function()
				return { project_path = { current_profile_table } }
			end
			local profile_config = require('java.api.profile_config')
			assert.has.error(function()
				profile_config.get_active_profile()
			end, 'No active profile')
		end)
	end)
end)
