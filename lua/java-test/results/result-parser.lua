local class = require('java-core.utils.class')

local MessageId = require('java-test.results.message-id')
local TestStatus = require('java-test.results.result-status')
local TestExecStatus = require('java-test.results.execution-status')

---@class java-test.TestParser
---@field private test_details java-test.TestResults[]
local TestParser = class()

---Init
function TestParser:_init()
	self.test_details = {}
end

---@private
TestParser.node_parsers = {
	[MessageId.TestTree] = 'parse_test_tree',
	[MessageId.TestStart] = 'parse_test_start',
	[MessageId.TestEnd] = 'parse_test_end',
	[MessageId.TestFailed] = 'parse_test_failed',
	[MessageId.TestError] = 'parse_test_failed',
}

---@private
TestParser.skip_prefixes = {
	'@Ignore:',
	'@AssumptionFailure:',
}

---@private
TestParser.strtobool = {
	['true'] = true,
	['false'] = false,
}

---Parse a given text into test details
---@param text string test result buffer
function TestParser:parse(text)
	if text:sub(-1) ~= '\n' then
		text = text .. '\n'
	end

	local line_iter = text:gmatch('(.-)\n')

	local line = line_iter()

	while line ~= nil do
		local message_id = line:sub(1, 8):gsub('%s+', '')
		local content = line:sub(9)

		local node_parser = TestParser.node_parsers[message_id]

		if node_parser then
			local data = vim.split(content, ',', { plain = true, trimempty = true })

			if self[TestParser.node_parsers[message_id]] then
				self[TestParser.node_parsers[message_id]](self, data, line_iter)
			end
		end

		line = line_iter()
	end
end

---Returns the parsed test details
---@return java-test.TestResults # parsed test details
function TestParser:get_test_details()
	return self.test_details
end

---@private
function TestParser:parse_test_tree(data)
	local node = {
		test_id = tonumber(data[1]),
		test_name = data[2],
		is_suite = TestParser.strtobool[data[3]],
		test_count = tonumber(data[4]),
		is_dynamic_test = TestParser.strtobool[data[5]],
		parent_id = tonumber(data[6]),
		display_name = data[7],
		parameter_types = data[8],
		unique_id = data[9],
	}

	local parent = self:find_result_node(node.parent_id)

	if not parent then
		table.insert(self.test_details, node)
	else
		parent.children = parent.children or {}
		table.insert(parent.children, node)
	end
end

---@private
function TestParser:parse_test_start(data)
	local test_id = tonumber(data[1])
	local node = self:find_result_node(test_id)
	assert(node)
	node.result = {}
	node.result.execution = TestExecStatus.Started
end

---@private
function TestParser:parse_test_end(data)
	local test_id = tonumber(data[1])
	local node = self:find_result_node(test_id)
	assert(node)
	node.result.execution = TestExecStatus.Ended

	for _, prefix in ipairs(TestParser.skip_prefixes) do
		if string.match(data[2], '^'..prefix) then
			node.result.status = TestStatus.Skipped
		end
	end
end

---@private
function TestParser:parse_test_failed(data, line_iter)
	local test_id = tonumber(data[1])
	local node = self:find_result_node(test_id)
	assert(node)

	node.result.status = node.result.status or TestStatus.Failed

	for _, prefix in ipairs(TestParser.skip_prefixes) do
		if string.match(data[2], '^'..prefix) then
			node.result.status = TestStatus.Skipped
		end
	end

	while true do
		local line = line_iter()

		if line == nil then
			break
		end

		-- EXPECTED
		if vim.startswith(line, MessageId.ExpectStart) then
			node.result.expected = self:get_content_until_end_tag(MessageId.ExpectEnd, line_iter)

		-- ACTUAL
		elseif vim.startswith(line, MessageId.ActualStart) then
			node.result.actual = self:get_content_until_end_tag(MessageId.ActualEnd, line_iter)

		-- TRACE
		elseif vim.startswith(line, MessageId.TraceStart) then
			node.result.trace = self:get_content_until_end_tag(MessageId.TraceEnd, line_iter)
		end
	end
end

---@private
function TestParser:get_content_until_end_tag(end_tag, line_iter)
	local content = {}

	while true do
		local line = line_iter()

		if line == nil or vim.startswith(line, end_tag) then
			break
		end

		table.insert(content, line)
	end

	return content
end

---@private
function TestParser:find_result_node(id)
	local function find_node(nodes)
		if not nodes or #nodes == 0 then
			return
		end

		for _, node in ipairs(nodes) do
			if node.test_id == id then
				return node
			end

			local _node = find_node(node.children)

			if _node then
				return _node
			end
		end
	end

	return find_node(self.test_details)
end

return TestParser

---@class java-test.TestResultExecutionDetails
---@field actual string[] lines
---@field expected string[] lines
---@field status java-test.TestStatus
---@field execution java-test.TestExecutionStatus
---@field trace string[] lines

---@class java-test.TestResults
---@field display_name string
---@field is_dynamic_test boolean
---@field is_suite boolean
---@field parameter_types string
---@field parent_id integer
---@field test_count integer
---@field test_id integer
---@field test_name string
---@field unique_id string
---@field result java-test.TestResultExecutionDetails
---@field children java-test.TestResults[]
