local tables = require('tables')

local M = {}

local function new(class, obj)
  local o = obj or {}
  setmetatable(o, class)
  class.__index = class
  return o
end

---@class Grid<T>
---@field data table<integer, T>
---@field xmax integer
---@field ymax integer
local Grid = {
  xmax = 0,
  ymax = 0,
}
M.Grid = Grid

function Grid:new(o)
  return new(Grid, o)
end

function Grid:contains_coords(x, y)
  return x > 0 and y > 0 and x <= self.xmax and y <= self.ymax
end

---@return Grid
function M.create(sizex, sizey, value)
  local g = Grid:new { xmax = sizex, ymax = sizey, data = {} }
  if not value then
    return g
  end

  for y = 1, sizey do
    for x = 1, sizex do
      local v = value
      if type(value) == "function" then
        v = value(x, y)
      end
      table.insert(g.data, v)
    end
  end
  return g
end

---@return integer
local function key(grid, x, y)
  return x + (y - 1) * grid.xmax
end

---@generic T
---@param x integer
---@param y integer
---@param o T
function Grid:set(x, y, o)
  self.data[key(self, x, y)] = o
end

function Grid:at(x, y)
  return self.data[key(self, x, y)]
end

function Grid:__tostring()
  local strings = M.create(self.xmax, self.ymax)
  local max_size = 0

  for y = 1, self.ymax do
    for x = 1, self.xmax do
      local displayed = tables.dump(self:at(x, y))
      strings:set(x, y, displayed)

      if #displayed > max_size then max_size = #displayed end
    end
  end

  local str = ""
  local linesep = ""
  for y = 1, self.ymax do
    local line = ""
    local sep = ""
    for x = 1, self.xmax do
      local displayed = strings:at(x, y)
      local pad_dist = max_size - #displayed
      for i = 1, pad_dist do
        line = line .. " "
      end
      line = line .. sep .. displayed
      if max_size > 1 then
        sep = " "
      end
    end
    str = str .. linesep .. line
    linesep = "\n"
  end
  return str
end

---read a grid and transform any tile into something thanks to the mapping
---@generic T
---@param lines string[]
---@param mapping function<string, T>
---@return Grid<T>
function M.read_from_lines(lines, mapping)
  local g = Grid:new()
  if #lines == 0 then
    error("cant create a grid with 0 line")
  end

  g.ymax = #lines
  g.xmax = #lines[1]
  g.data = {}

  for _, line in pairs(lines) do
    local chars = tables.chars_of(line)
    for _, c in pairs(chars) do
      table.insert(g.data, mapping(c))
    end
  end
  return g
end

return M
