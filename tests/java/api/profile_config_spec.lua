local mock = require('luassert.mock')
local Profile = require('java.api.profile_config').Profile
local spy = require('luassert.spy')

describe('java.api.profile_config', function()
	local project_path = 'project_path'
	local mock_fn = {}
	local mock_io = {}
	local file_mock = {
		read = function(_, readmode)
			assert(readmode == '*a')
			return '{ "test": "test" }'
		end,
		close = function() end,
		write = function() end,
	}

	local json_encode = vim.fn.json_encode
	local json_decode = vim.fn.json_decode

	before_each(function()
		package.loaded['java.api.profile_config'] = nil
		mock_io = mock(io, true)
		mock_fn = mock(vim.fn, true)

		mock_fn.json_decode = function(data)
			return json_decode(data)
		end

		mock_fn.json_encode = function(data)
			return json_encode(data)
		end

		mock_fn.getcwd = function()
			return project_path
		end

		mock_fn.stdpath = function()
			return 'config_path'
		end

		mock_fn.expand = function()
			return project_path
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
			profile_config.setup()
			assert.same(profile_config.get_all_profiles('module1 -> main_class'), {})
		end)

		it('when config cannot be decoded', function()
			file_mock.read = function(_, readmode)
				assert(readmode == '*a')
				return '{'
			end
			mock_io.open = function()
				return file_mock
			end

			local profile_config = require('java.api.profile_config')
			profile_config.setup(project_path)
			assert.same(profile_config.get_all_profiles('module1 -> main_class'), {})
		end)

		it('successfully', function()
			file_mock.read = function(_, readmode)
				assert(readmode == '*a')
				return '{ "project_path": \
									{ \
										"module1 -> main_class": {\
											"profile_name1":{ \
												"vm_args": "vm_args",\
												"prog_args": "prog_args",\
												"name": "profile_name1",\
												"is_active": true }\
										} \
									}\
								}'
			end

			mock_io.open = function(config_path, mode)
				assert(config_path == 'config_path/nvim-java-profiles.json')
				assert(mode == 'r')
				return file_mock
			end

			local profile_config = require('java.api.profile_config')
			profile_config.setup(project_path)
			assert.same(profile_config.get_all_profiles('module1 -> main_class'), {
				profile_name1 = Profile('vm_args', 'prog_args', 'profile_name1', true),
			})
		end)
	end)

	describe('add_or_update_profile', function()
		it('when updating profile', function()
			local input_profile =
				Profile('vm_args_updated', 'prog_args_updated', 'name', true)

			mock_io.open = function()
				return file_mock
			end

			file_mock.read = function(_, readmode)
				assert(readmode == '*a')
				return '{ "project_path": {\
									"module1 -> main_class": {\
										"profile_name1":{\
											"vm_args": "vm_args",\
											"prog_args": "prog_args",\
											"name": "name",\
											"is_active": true }\
									}\
								}\
							}'
			end

			local spy_close = spy.on(file_mock, 'close')

			-- call the function
			local profile_config = require('java.api.profile_config')
			profile_config.setup()
			profile_config.add_or_update_profile(
				input_profile,
				'name',
				'module1 -> main_class'
			)
			--- verify
			assert.same(
				{ name = input_profile },
				profile_config.get_all_profiles('module1 -> main_class')
			)
			assert.spy(spy_close).was_called(3) -- init, full_config, save
		end)
	end)

	it('when add new profile (set activate automatically)', function()
		local input_profile = Profile('vm_args2', 'prog_args2', 'name2')

		mock_io.open = function()
			return file_mock
		end

		file_mock.read = function(_, readmode)
			assert(readmode == '*a')
			return '{ "project_path": { \
								"module1 -> main_class": [\
									{ \
										"vm_args": "vm_args1",\
										"prog_args": "prog_args1",\
										"name": "name1",\
										"is_active": true }\
								]\
							}\
						}'
		end

		mock_fn.json_encode = function(data)
			local expected1_id = 1
			local expected2_id = 2

			if data.project_path['module1 -> main_class'][1].name == 'name2' then
				expected1_id = 2
				expected2_id = 1
			end

			assert.same(data.project_path['module1 -> main_class'][expected1_id], {
				vm_args = 'vm_args1',
				prog_args = 'prog_args1',
				name = 'name1',
				is_active = false,
			})
			assert.same(data.project_path['module1 -> main_class'][expected2_id], {
				vm_args = 'vm_args2',
				prog_args = 'prog_args2',
				name = 'name2',
				is_active = true,
			})
			return json_encode(data)
		end

		local spy_close = spy.on(file_mock, 'close')

		-- call the function
		local profile_config = require('java.api.profile_config')
		profile_config.setup()
		profile_config.add_or_update_profile(
			input_profile,
			nil,
			'module1 -> main_class'
		)

		local expected_app_profiles_output = {
			name1 = Profile('vm_args1', 'prog_args1', 'name1', false),
			name2 = Profile('vm_args2', 'prog_args2', 'name2', true),
		}
		assert.same(
			profile_config.get_all_profiles('module1 -> main_class'),
			expected_app_profiles_output
		)
		assert.spy(spy_close).was_called(3) -- init, full_config, save
	end)

	it('when profile already exists', function()
		-- setup
		local input_profile = Profile('vm_args1', 'prog_args1', 'name1')

		-- mocks/verify mocks calls with expected values
		mock_io.open = function()
			return file_mock
		end

		file_mock.read = function(_, readmode)
			assert(readmode == '*a')
			return '{ "project_path": { \
								"module1 -> main_class": {\
									"profile_name1":{\
										"vm_args": "vm_args1",\
										"prog_args": "prog_args1",\
										"name": "name1",\
										"is_active": true }\
								}\
							}\
						}'
		end

		-- call the function
		local profile_config = require('java.api.profile_config')
		profile_config.setup()
		assert.has.error(function()
			profile_config.add_or_update_profile(
				input_profile,
				nil,
				'module1 -> main_class'
			)
		end, "Profile with name 'name1' already exists")
	end)

	it('when profile name is required', function()
		-- setup
		local input_profile = Profile('vm_args', 'prog_args', nil)

		-- call the function
		local profile_config = require('java.api.profile_config')
		profile_config.setup()
		assert.has.error(function()
			profile_config.add_or_update_profile(
				input_profile,
				nil,
				'module1 -> main_class'
			)
		end, 'Profile name is required')
	end)

	it('set_active_profile', function()
		-- mocks/verify mocks calls with expected values
		mock_io.open = function()
			return file_mock
		end

		file_mock.read = function(_, readmode)
			assert(readmode == '*a')
			return '{ "project_path": \
									{ \
										"module1 -> main_class": [{ \
												"vm_args": "vm_args",\
												"prog_args": "prog_args",\
												"name": "name1",\
												"is_active": true \
												},\
											{ \
												"vm_args": "vm_args",\
												"prog_args": "prog_args",\
												"name": "name2",\
												"is_active": false \
											}] \
									}\
							}'
		end

		local spy_close = spy.on(file_mock, 'close')

		-- call the function
		local profile_config = require('java.api.profile_config')
		profile_config.setup()
		profile_config.set_active_profile('name2', 'module1 -> main_class')

		--- verify
		assert.same(
			profile_config.get_active_profile('module1 -> main_class'),
			Profile('vm_args', 'prog_args', 'name2', true)
		)
		assert.spy(spy_close).was_called(3) -- init, full_config, save
	end)

	it('get_profile_by_name', function()
		-- setup

		-- mocks/verify mocks calls with expected values
		mock_io.open = function()
			return file_mock
		end

		file_mock.read = function(_, readmode)
			assert(readmode == '*a')
			return '{ "project_path": \
									{ \
										"module1 -> main_class": [{ \
												"vm_args": "vm_args1",\
												"prog_args": "prog_args1",\
												"name": "name1",\
												"is_active": true \
												},\
											{ \
												"vm_args": "vm_args2",\
												"prog_args": "prog_args2",\
												"name": "name2",\
												"is_active": false \
											}] \
									}\
							}'
		end

		-- call the function
		local profile_config = require('java.api.profile_config')
		profile_config.setup()
		local profile = profile_config.get_profile('name1', 'module1 -> main_class')
		--- verify
		assert.same(profile, Profile('vm_args1', 'prog_args1', 'name1', true))
	end)

	describe('get_active_profile', function()
		-- mocks/verify mocks calls with expected values

		file_mock.read = function(_, readmode)
			assert(readmode == '*a')
			return '{ "project_path": \
									{ \
										"module1 -> main_class": [{ \
												"vm_args": "vm_args1",\
												"prog_args": "prog_args1",\
												"name": "name1",\
												"is_active": true \
												},\
											{ \
												"vm_args": "vm_args2",\
												"prog_args": "prog_args2",\
												"name": "name2",\
												"is_active": false \
											}] \
									}\
							}'
		end

		it('succesfully', function()
			-- setup
			mock_io.open = function()
				return file_mock
			end

			-- call the function
			local profile_config = require('java.api.profile_config')
			profile_config.setup()
			local profile = profile_config.get_active_profile('module1 -> main_class')

			--- verify
			assert.same(profile, Profile('vm_args1', 'prog_args1', 'name1', true))
		end)

		it('when number_of_profiles == 0', function()
			-- setup
			file_mock.read = function(_, readmode)
				assert(readmode == '*a')
				return '{ "project_path": { "module1 -> main_class": [] } }'
			end

			mock_io.open = function()
				return file_mock
			end

			-- call the function
			local profile_config = require('java.api.profile_config')
			profile_config.setup()
			local profile = profile_config.get_active_profile('module1 -> main_class')
			-- verify
			assert(profile == nil)
		end)

		it('when number_of_profiles > 0', function()
			mock_io.open = function()
				return file_mock
			end

			file_mock.read = function(_, readmode)
				assert(readmode == '*a')
				return '{ "project_path": { "module1 -> main_class": [{ \
												"vm_args": "vm_args1",\
												"prog_args": "prog_args1",\
												"name": "name1",\
												"is_active": false \
											}] } }'
			end

			local profile_config = require('java.api.profile_config')
			profile_config.setup()
			assert.has.error(function()
				profile_config.get_active_profile('module1 -> main_class')
			end, 'No active profile')
		end)
	end)
end)
