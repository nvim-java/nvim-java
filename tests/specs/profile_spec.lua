local assert = require('luassert')

local function with_package_overrides(overrides, callback)
	local original = {}

	for module_name, module_value in pairs(overrides) do
		original[module_name] = package.loaded[module_name]
		package.loaded[module_name] = module_value
	end

	local ok, result = pcall(callback)

	for module_name, module_value in pairs(original) do
		package.loaded[module_name] = module_value
	end

	for module_name, _ in pairs(overrides) do
		if original[module_name] == nil then
			package.loaded[module_name] = nil
		end
	end

	package.loaded['java-dap'] = nil

	if not ok then
		error(result)
	end

	return result
end

describe('Profile env utils', function()
	it('parses env lines and stringifies sorted keys', function()
		local env_utils = require('java.utils.env')
		local env, err = env_utils.parse_lines({
			'# comment',
			'',
			'export FOO = bar',
			'BAR="baz qux"',
			"QUX='quoted'",
		})

		assert.is_nil(err)
		assert.same({
			FOO = 'bar',
			BAR = 'baz qux',
			QUX = 'quoted',
		}, env)
		assert.equals('BAR=baz qux\nFOO=bar\nQUX=quoted', env_utils.stringify(env))
	end)

	it('resolves relative env files from project cwd and merges inline env last', function()
		local env_utils = require('java.utils.env')
		local original_cwd = vim.fn.getcwd()
		local temp_root = vim.fn.tempname()
		local project_dir = temp_root .. '/project'
		local other_dir = temp_root .. '/other'

		local ok, result = pcall(function()
			vim.fn.mkdir(project_dir, 'p')
			vim.fn.mkdir(other_dir, 'p')
			vim.fn.writefile({ 'FROM_FILE=1', 'OVERRIDE=file' }, project_dir .. '/.env.dev')

			vim.cmd.lcd(other_dir)

			local env, err = env_utils.read_file('.env.dev', project_dir)
			assert.is_nil(err)
			assert.same({
				FROM_FILE = '1',
				OVERRIDE = 'file',
			}, env)

			local merged_env, merged_err = env_utils.load_profile_env({
				env_file = '.env.dev',
				env = {
					INLINE = '2',
					OVERRIDE = 'inline',
				},
			}, project_dir)

			assert.is_nil(merged_err)
			assert.same({
				FROM_FILE = '1',
				INLINE = '2',
				OVERRIDE = 'inline',
			}, merged_env)
		end)

		vim.cmd.lcd(original_cwd)
		vim.fn.delete(temp_root, 'rf')

		if not ok then
			error(result)
		end
	end)

	it('returns helpful errors for invalid env content', function()
		local env_utils = require('java.utils.env')
		local env, err = env_utils.parse_lines({ 'NOT VALID' })

		assert.same({}, env)
		assert.equals('Line 1: Expected KEY=VALUE', err)
	end)
end)

describe('Java DAP profile application', function()
	it('preserves user configs while replacing managed ones', function()
		local fake_dap = {
			adapters = {},
			configurations = {
				java = {
					{ name = 'user-config', request = 'launch' },
					{ name = 'stale-managed', _nvim_java_managed = true },
				},
			},
			session = nil,
			terminate = function() end,
		}

		local fake_profile = {
			vm_args = '-Xmx1g',
			prog_args = '--debug',
			env = { INLINE = '1' },
			env_file = '.env.dev',
		}

		with_package_overrides({
			['async.runner'] = function(callback)
				local runner_result
				runner_result = {
					catch = function(_)
						return runner_result
					end,
					run = function()
						callback()
					end,
				}

				return runner_result
			end,
			['java-core.utils.error_handler'] = function()
				return function(err)
					error(err)
				end
			end,
			['java-core.utils.lsp'] = {
				get_jdtls = function()
					return { id = 1 }
				end,
			},
			['dap'] = fake_dap,
			['java.api.profile_config'] = {
				current_project_path = '/tmp/project',
				get_active_profile = function(name)
					if name == 'main-class' then
						return fake_profile
					end
				end,
			},
			['java.utils.env'] = {
				load_profile_env = function(profile, base_dir)
					assert.same(fake_profile, profile)
					assert.equals('/tmp/project', base_dir)
					return {
						FROM_FILE = 'yes',
						INLINE = '1',
					}, nil
				end,
			},
			['java-core.utils.notify'] = {
				error = function(err)
					error(err)
				end,
			},
			['java-dap.setup'] = function(client)
				assert.same({ id = 1 }, client)
				return {
					get_dap_adapter = function()
						return { type = 'server', host = '127.0.0.1', port = 5005 }
					end,
					get_dap_config = function()
						return {
							{ name = 'main-class', cwd = '/tmp/project/app' },
						}
					end,
				}
			end,
		}, function()
			local java_dap = require('java-dap')
			java_dap.config_dap()
		end)

		assert.equals(2, #fake_dap.configurations.java)
		assert.same({ name = 'user-config', request = 'launch' }, fake_dap.configurations.java[1])
		assert.same({
			name = 'main-class',
			cwd = '/tmp/project/app',
			vmArgs = '-Xmx1g',
			args = '--debug',
			env = {
				FROM_FILE = 'yes',
				INLINE = '1',
			},
			envFile = '.env.dev',
			_nvim_java_managed = true,
		}, fake_dap.configurations.java[2])
	end)
end)
