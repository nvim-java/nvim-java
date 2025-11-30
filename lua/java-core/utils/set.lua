---@class Set: List
local M = {}

---Returns a new set
---@param o? any[]
---@return Set
function M:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

---Appends a value into to the list if the value is not already in the list
---@param value any
function M:push(value)
	if not self:includes(value) then
		table.insert(self, value)
	end
end

return M
