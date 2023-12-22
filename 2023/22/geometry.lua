local M = {}

local function new(class, obj)
  local o = obj or {}
  setmetatable(o, class)
  class.__index = class
  return o
end

---@class Pos3
---@field x integer
---@field y integer
---@field z integer
local Pos3 = {}
M.Pos3 = Pos3

---@return Pos3
function Pos3:new(o)
  return new(Pos3, o)
end

---@param x integer
---@param y integer
---@param z integer
function M.pos3(x, y, z)
  return Pos3:new { x = x, y = y, z = z }
end

function Pos3:__tostring()
  return string.format("(%d, %d, %d)", self.x, self.y, self.z)
end

return M
