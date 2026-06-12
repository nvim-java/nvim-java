local M = {}

local uv = vim.uv or vim.loop

---Recursively copy a directory
---@param src string
---@param dest string
local function copy_dir(src, dest)
	vim.fn.mkdir(dest, 'p')

	for name, type in vim.fs.dir(src) do
		local src_path = src .. '/' .. name
		local dest_path = dest .. '/' .. name

		if type == 'directory' then
			copy_dir(src_path, dest_path)
		else
			assert(uv.fs_copyfile(src_path, dest_path), 'failed to copy ' .. src_path)
		end
	end
end

---Copy a fixture project to a temp dir (outside the repo so root markers
---resolve to the fixture, not the plugin repo) and cd into it
---@param fixture string fixture dir name under tests/fixtures
---@return string project_root absolute path of the copied project
function M.open(fixture)
	local src = vim.fn.fnamemodify('tests/fixtures/' .. fixture, ':p')
	local dest = vim.fn.tempname() .. '-' .. fixture

	copy_dir(src, dest)
	vim.cmd.cd(dest)

	return dest
end

---Wait until cond() is truthy or fail the test
---@param cond fun(): any
---@param timeout number ms
---@param msg string
function M.wait_for(cond, timeout, msg)
	local ok = vim.wait(timeout, function()
		return cond() and true or false
	end, 200)

	if not ok then
		error(string.format('timed out after %dms waiting for: %s', timeout, msg))
	end
end

---Run a workspace command on the client and wait for the response
---@param client vim.lsp.Client
---@param command string
---@param arguments? any[]
---@param timeout? number ms
---@return any # command result or nil on error/timeout
function M.execute_command(client, command, arguments, timeout)
	local done = false
	local cmd_result

	client:request('workspace/executeCommand', {
		command = command,
		arguments = arguments,
	}, function(err, result)
		done = true
		if not err then
			cmd_result = result
		end
	end)

	vim.wait(timeout or 10000, function()
		return done
	end, 100)

	return cmd_result
end

---Wait until the project is imported by polling main class resolution
---@param client vim.lsp.Client
---@param timeout number ms
---@return table[] # resolved main classes
function M.wait_for_import(client, timeout)
	local deadline = uv.now() + timeout

	while uv.now() < deadline do
		local result = M.execute_command(client, 'vscode.java.resolveMainClass')

		if result and #result > 0 then
			return result
		end

		vim.wait(2000)
	end

	error(string.format('project import did not complete within %dms', timeout))
end

---Collect leaf nodes from a test result tree
---@param results java-test.TestResults[]
---@return java-test.TestResults[]
function M.leaf_results(results)
	local leaves = {}

	local function walk(nodes)
		for _, node in ipairs(nodes) do
			if node.children and #node.children > 0 then
				walk(node.children)
			else
				table.insert(leaves, node)
			end
		end
	end

	walk(results)

	return leaves
end

---Get leaf results of the last test report, or nil if not available yet
---@return java-test.TestResults[] | nil
function M.last_report_leaves()
	local last_report = require('java-test').last_report

	if not last_report then
		return nil
	end

	local ok, results = pcall(function()
		return last_report:get_results()
	end)

	if not ok or not results then
		return nil
	end

	return M.leaf_results(results)
end

---Check all given leaves finished execution and passed
---Note: the result parser only sets status for Failed/Skipped tests;
---a passed test ends execution with no status
---@param leaves java-test.TestResults[]
---@param count number expected leaf count
---@return boolean
function M.all_passed(leaves, count)
	local execution_status = require('java-test.results.execution-status')

	if #leaves ~= count then
		return false
	end

	for _, leaf in ipairs(leaves) do
		if not leaf.result or leaf.result.execution ~= execution_status.Ended then
			return false
		end

		if leaf.result.status ~= nil then
			return false
		end
	end

	return true
end

return M
