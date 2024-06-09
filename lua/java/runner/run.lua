local class = require('java-core.utils.class')

---@class java.Run
---@field win  number
---@field bufnr number
---@field job_id number
---@field chan number
---@field dap_config java-dap.DapLauncherConfig
---@field running_status string
---@field is_open boolean
---@field is_running boolean
local Run = class()

---@param dap_config java-dap.DapLauncherConfig
function Run:_init(dap_config)
	self.is_open = false
	self.dap_config = dap_config
	self.bufnr = vim.api.nvim_create_buf(false, true)
end

return Run
