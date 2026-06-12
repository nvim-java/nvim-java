local lsp_utils = dofile('tests/utils/lsp-utils.lua')
local project = dofile('tests/utils/project.lua')
local assert = require('luassert')

local is_win = vim.fn.has('win32') == 1

local TIMEOUT = {
	attach = 60000,
	import = 300000,
	diagnostics = 60000,
	run = 120000,
	test = 180000,
}

describe('nvim-java integration', function()
	---@type vim.lsp.Client
	local jdtls

	---@type string
	local project_root

	it('attaches jdtls and spring-boot to a Java buffer', function()
		project_root = project.open('demo')

		vim.cmd.edit('src/main/java/com/example/Main.java')

		jdtls = lsp_utils.wait_for_lsp_attach('jdtls', TIMEOUT.attach)
		local spring = lsp_utils.wait_for_lsp_attach('spring-boot', TIMEOUT.attach)

		assert.is_not_nil(jdtls, 'JDTLS should attach to Java buffer')
		assert.is_not_nil(spring, 'Spring Boot should attach to Java buffer')
	end)

	it('bundles java-test, java-debug and spring-boot-tools extensions', function()
		local bundles = jdtls.config.init_options.bundles

		assert.is_not_nil(bundles, 'Bundles should be configured')
		assert.is_true(#bundles > 0, 'Bundles should not be empty')

		local has_java_test = false
		local has_java_debug = false
		local has_spring_boot = false

		for _, bundle in ipairs(bundles) do
			if bundle:match('java%-test') and bundle:match('com%.microsoft%.java%.test%.plugin') then
				has_java_test = true
			end
			if bundle:match('java%-debug') and bundle:match('com%.microsoft%.java%.debug%.plugin') then
				has_java_debug = true
			end
			if bundle:match('spring%-boot%-tools') and bundle:match('jdt%-ls%-extension%.jar') then
				has_spring_boot = true
			end
		end

		assert.is_true(has_java_test, 'java-test extension should be bundled')
		assert.is_true(has_java_debug, 'java-debug extension should be bundled')
		assert.is_true(has_spring_boot, 'spring-boot-tools extension should be bundled')
	end)

	it('imports the maven project and resolves the main class', function()
		local mains = project.wait_for_import(jdtls, TIMEOUT.import)

		assert.equals('com.example.Main', mains[1].mainClass)
	end)

	it('registers dap configurations for the main class', function()
		require('dap').configurations.java = {}
		require('java-dap').config_dap()

		project.wait_for(function()
			local configs = require('dap').configurations.java or {}

			for _, config in ipairs(configs) do
				if config.mainClass == 'com.example.Main' then
					return true
				end
			end
		end, TIMEOUT.run, 'dap configuration for com.example.Main')
	end)

	it('publishes and clears diagnostics on buffer changes', function()
		local buf = vim.api.nvim_get_current_buf()
		local original = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

		vim.api.nvim_buf_set_lines(buf, 2, 3, false, { 'public class Main {', 'this is not valid java;' })

		project.wait_for(function()
			return #vim.diagnostic.get(buf) > 0
		end, TIMEOUT.diagnostics, 'diagnostics on broken buffer')

		vim.api.nvim_buf_set_lines(buf, 0, -1, false, original)

		project.wait_for(function()
			return #vim.diagnostic.get(buf) == 0
		end, TIMEOUT.diagnostics, 'diagnostics to clear on fixed buffer')
	end)

	it('runs the main class with the built-in runner', function()
		if is_win then
			return
		end

		vim.cmd('JavaRunnerRunMain')

		project.wait_for(function()
			local run = require('java.api.runner').runner.curr_run

			if not run then
				return false
			end

			-- terminal buffer wraps output at window width, so join without
			-- newlines before matching
			local lines = vim.api.nvim_buf_get_lines(run.buffer, 0, -1, false)
			return table.concat(lines, ''):match('Hello from nvim%-java') ~= nil
		end, TIMEOUT.run, 'runner output of com.example.Main')
	end)

	it('toggles the runner log window', function()
		if is_win then
			return
		end

		-- the log window opens automatically when a run starts
		local logger = require('java.api.runner').runner.logger
		assert.is_true(logger:is_opened(), 'log window should open automatically on run')

		local win_count = #vim.api.nvim_list_wins()

		vim.cmd('JavaRunnerToggleLogs')
		project.wait_for(function()
			return #vim.api.nvim_list_wins() == win_count - 1
		end, TIMEOUT.attach, 'runner log window to close')

		vim.cmd('JavaRunnerToggleLogs')
		project.wait_for(function()
			return #vim.api.nvim_list_wins() == win_count
		end, TIMEOUT.attach, 'runner log window to reopen')
	end)

	it('stops the main class run', function()
		if is_win then
			return
		end

		vim.cmd('JavaRunnerStopMain')

		project.wait_for(function()
			return not require('java.api.runner').runner.curr_run.is_running
		end, TIMEOUT.run, 'runner to stop')
	end)

	it('runs the current test class', function()
		vim.cmd.edit(project_root .. '/src/test/java/com/example/MainTest.java')
		lsp_utils.wait_for_lsp_attach('jdtls', TIMEOUT.attach)

		vim.cmd('JavaTestRunCurrentClass')

		project.wait_for(function()
			local leaves = project.last_report_leaves()
			return leaves and project.all_passed(leaves, 2)
		end, TIMEOUT.test, 'current test class to pass with 2 test results')
	end)

	it('runs the current test method', function()
		vim.fn.search('greetReturnsGreeting')

		vim.cmd('JavaTestRunCurrentMethod')

		project.wait_for(function()
			local leaves = project.last_report_leaves()
			return leaves and project.all_passed(leaves, 1)
		end, TIMEOUT.test, 'current test method to pass with 1 test result')
	end)

	it('runs all tests in the project', function()
		vim.cmd('JavaTestRunAllTests')

		project.wait_for(function()
			local leaves = project.last_report_leaves()
			return leaves and project.all_passed(leaves, 2)
		end, TIMEOUT.test, 'all tests to pass with 2 test results')
	end)

	it('shows the last test report', function()
		local win_count = #vim.api.nvim_list_wins()
		local wins_before = vim.api.nvim_list_wins()

		vim.cmd('JavaTestViewLastReport')

		project.wait_for(function()
			return #vim.api.nvim_list_wins() == win_count + 1
		end, TIMEOUT.attach, 'test report window to open')

		for _, win in ipairs(vim.api.nvim_list_wins()) do
			if not vim.tbl_contains(wins_before, win) then
				pcall(vim.api.nvim_win_close, win, true)
			end
		end
	end)

	it('opens the profile editor ui', function()
		local win_count = #vim.api.nvim_list_wins()
		local wins_before = vim.api.nvim_list_wins()

		vim.cmd('JavaProfile')

		project.wait_for(function()
			return #vim.api.nvim_list_wins() > win_count
		end, TIMEOUT.run, 'profile editor windows to open')

		for _, win in ipairs(vim.api.nvim_list_wins()) do
			if not vim.tbl_contains(wins_before, win) then
				pcall(vim.api.nvim_win_close, win, true)
			end
		end
	end)

	it('changes the default runtime', function()
		local java_exec = vim.fn.exepath('java')
		local java_home = vim.fs.dirname(vim.fs.dirname(java_exec))

		-- paths must be distinct; change_runtime marks default by path equality
		jdtls.config.settings = vim.tbl_deep_extend('force', jdtls.config.settings or {}, {
			java = {
				configuration = {
					runtimes = {
						{ name = 'JavaSE-17', path = java_home .. '-other' },
						{ name = 'JavaSE-21', path = java_home },
					},
				},
			},
		})

		local original_select = vim.ui.select
		---@diagnostic disable-next-line: duplicate-set-field
		vim.ui.select = function(items, _, on_choice)
			on_choice(items[2], 2)
		end

		vim.cmd('JavaSettingsChangeRuntime')

		local runtimes = jdtls.config.settings.java.configuration.runtimes

		project.wait_for(function()
			return runtimes[2].default == true and runtimes[1].default == nil
		end, TIMEOUT.attach, 'second runtime to become default')

		vim.ui.select = original_select
	end)
end)
