local class = require('java-core.utils.class')
local log = require('java-core.utils.log2')

---@class java-dap.DapRunner
---@field private server uv_tcp_t
local Runner = class()

---@return java-dap.DapRunner
function Runner:new()
	local o = {
		server = nil,
	}

	setmetatable(o, self)
	self.__index = self
	return o
end

---Dap run with given config
---@param config java-dap.DapLauncherConfig
---@param report java-test.JUnitTestReport
function Runner:run_by_config(config, report)
	log.debug('running dap with config: ', config)

	require('dap').run(config --[[@as Configuration]], {
		before = function(conf)
			return self:before(conf, report)
		end,

		after = function()
			return self:after()
		end,
	})
end

---Runs before the dap run
---@private
---@param conf java-dap.DapLauncherConfig
---@param report java-test.JUnitTestReport
---@return java-dap.DapLauncherConfig
function Runner:before(conf, report)
	log.debug('running "before" callback')

	self.server = assert(vim.loop.new_tcp(), 'uv.new_tcp() must return handle')
	self.server:bind('127.0.0.1', 0)
	self.server:listen(128, function(err)
		assert(not err, err)

		local sock = assert(vim.loop.new_tcp(), 'uv.new_tcp must return handle')
		self.server:accept(sock)
		local success = sock:read_start(report:get_stream_reader(sock))
		assert(success == 0, 'failed to listen to reader')
	end)

	-- replace the port number in the generated args
	conf.args = conf.args:gsub('-port ([0-9]+)', '-port ' .. self.server:getsockname().port)

	return conf
end

---Runs after the dap run
---@private
function Runner:after()
	log.debug('running "after" callback')

	if self.server then
		self.server:shutdown()
		self.server:close()
	end
end

return Runner
