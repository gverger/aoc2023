local tables = require('tables')
local files = require('files')
local log = require('log')
local grid = require('grid')

log.LEVEL = log.LEVELS.DEBUG

local function new(class, obj)
  local o = obj or {}
  setmetatable(o, class)
  class.__index = class
  return o
end

local directions = {
  { 1,  0 },
  { -1, 0 },
  { 0,  1 },
  { 0,  -1 },
}

local function turn(direction)
  local next = {}
  if direction[1] == 0 then
    table.insert(next, { 1, 0 })
    table.insert(next, { -1, 0 })
  end
  if direction[2] == 0 then
    table.insert(next, { 0, 1 })
    table.insert(next, { 0, -1 })
  end
  return next
end

local function dir_to_key(dir)
  if dir[1] > 0 then return "r" end
  if dir[1] < 0 then return "l" end
  if dir[2] > 0 then return "d" end
  if dir[2] > 0 then return "u" end
  return "0"
end

---@class Node
---@field x integer
---@field y integer
---@field g integer
---@field h integer
---@field parent Node?
---@field key string

---@class OpenList
---@field data table<string, Node[]>
---@field lookup table<integer, Node>
---@field size integer
---@field current integer
---@field key function<integer, string>
OpenList = {}

---@return OpenList
function OpenList:new(o)
  local l = new(OpenList, o)
  l.data = {}
  l.lookup = {}
  l.size = 0
  l.current = 0
  l.key = l.key or function(node) return node.x .. "-" .. node.y end
  return l
end

---@param node Node
function OpenList:add(node)
  node.key = node.key or self.key(node)
  if self.current > node.g + node.h then
    self.current = node.g + node.h
  end

  local there = self.lookup[node.key]
  if there then
    if node.g < there.g then
      local f = there.g + there.h
      self.data[f][node.key] = nil
      there.g = node.g
      there.parent = node.parent
    else
      return
    end
  else
    self.size = self.size + 1
  end

  self.lookup[node.key] = node

  local f = node.g + node.h
  if not self.data[f] then
    self.data[f] = {}
  end

  self.data[f][node.key] = node
end

---@return Node?
function OpenList:pop()
  while not self.data[self.current] or tables.is_empty(self.data[self.current]) do
    self.current = self.current + 1
  end
  local n = tables.first_value(self.data[self.current])
  self.data[self.current][n.key] = nil
  self.lookup[n.key] = nil
  self.size = self.size - 1

  return n
end

local dist_nodes = 0

local function distances_to_goal(map)
  local distances = grid.create(map.xmax, map.ymax, 1000000)

  local open = OpenList:new()
  open:add({ x = map.xmax, y = map.ymax, g = 0, h = 0, parent = nil })

  distances:set(map.xmax, map.ymax, map:at(map.xmax, map.ymax))

  while open.size > 0 do
    dist_nodes = dist_nodes + 1
    local n = open:pop()
    if not n then break end

    for _, d in pairs(directions) do
      local nx = n.x + d[1]
      local ny = n.y + d[2]
      if map:contains_coords(nx, ny) then
        local heat = map:at(nx, ny) + distances:at(n.x, n.y)
        if heat < distances:at(nx, ny) then
          distances:set(nx, ny, heat)
          local next = { x = nx, y = ny, parent = n, g = heat, h = 0 }
          open:add(next)
        end
      end
    end
  end

  print("dist nodes = " .. dist_nodes)
  return distances
end

local function astar(map, best_possible, min_fw, max_fw)
  local nodes = 0
  local first = { x = 1, y = 1, direction = { 0, 0 }, g = -map:at(1, 1), h = best_possible(1, 1) }
  local open = OpenList:new {
    key = function(node) return node.x .. dir_to_key(node.direction) .. node.y end,
  }
  open:add(first)

  local current_f = first.g + first.h

  local close = grid.create(map.xmax, map.ymax, function() return {} end)

  while open.size > 0 do
    local node = open:pop()
    if node == nil then
      print("nodes = " .. nodes)
      return nil
    end
    nodes = nodes + 1
    local dk = dir_to_key(node.direction)
    if dk then
      close:at(node.x, node.y)[dk] = true
    end
    if node.x == map.xmax and node.y == map.ymax then
      print("nodes = " .. nodes)
      return node
    end
    if node.g + node.h > current_f then
      current_f = node.g + node.h
      -- print(current_f)
    end

    local dirs = turn(node.direction)
    for _, dir in pairs(dirs) do
      local x = node.x
      local y = node.y
      local g = node.g
      for i = 1, max_fw do
        g = g + map:at(x, y)
        x = x + dir[1]
        y = y + dir[2]
        if not map:contains_coords(x, y) then
          break
        end
        if i < min_fw then
          goto continue
        end
        if not close:at(x, y)[dir_to_key(dir)] then
          local neighbour = {
            x = x,
            y = y,
            direction = { dir[1] * i, dir[2] * i },
            g = g,
            h = best_possible(x, y),
            parent = node,
          }
          open:add(neighbour)
        end
        ::continue::
      end
    end
  end
  print("nodes = " .. nodes)
  return nil
end

local function run(inputfile)
  print("Running " .. inputfile)
  local lines = files.lines_from(inputfile)

  local map = grid.read_from_lines(lines, tonumber)
  local distances = distances_to_goal(map)

  print(map)
  -- print()
  -- print(distances)

  -- local step = astar(map, function(x, y) return distances:at(x, y) end, 1, 3)
  local step = astar(map, function(x, y) return distances:at(x, y) end, 4, 10)

  -- local step = astar(map, function(x, y) return 0 end, 1, 3)
  -- local step = astar(map, function(x, y) return 0 end, 4, 10)

  local res_to_string = function(self)
    if self.highlighted then
      return '\27[31m' .. self.value .. '\27[0m'
    end
    return self.value
  end

  local res_tile = function(x, y)
    local tile = {
      value = map:at(x, y),
      __tostring = res_to_string,
    }
    setmetatable(tile, tile)
    return tile
  end

  local res = grid.create(map.xmax, map.ymax, res_tile)


  local steps = {}
  while step do
    table.insert(steps, 1, step)
    step = step.parent
  end
  for _, step in ipairs(steps) do
    if step.parent then
      for x = math.min(step.x, step.parent.x), math.max(step.x, step.parent.x) do
        for y = math.min(step.y, step.parent.y), math.max(step.y, step.parent.y) do
          res:at(x, y).highlighted = true
        end
      end
    end
    -- print(step.x .. ", " .. step.y .. " g = " .. step.g .. " h = " .. step.h .. " f = " .. step.g + step.h)
  end

  print(res)
  local last = steps[#steps]
  print(last.x .. ", " .. last.y .. " g = " .. last.g .. " h = " .. last.h .. " f = " .. last.g + last.h)
end

--------------------------------------------------------------------------
--- TESTS
--------------------------------------------------------------------------

local assert = require('test').assert

local test = {}

function test.all()
end

-- local profile = require('profile')
-- profile.start()

-- test.all()
-- run("small.txt")
-- run("part1.txt")
run("input.txt")

-- profile.stop()
-- print(profile.report(20))
