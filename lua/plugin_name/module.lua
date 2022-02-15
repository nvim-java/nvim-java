-- module represents a lua module for the plugin
local M = {}

M.my_first_function = function(var)
  return "my first function with param = " .. var
end

return M
