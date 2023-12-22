local tables = require('tables')
local files = require('files')
local log = require('log')
local grid = require('grid')
local geometry = require('geometry')

local pos3 = geometry.pos3
-- local Pos3 = geometry.Pos3

log.LEVEL = log.LEVELS.NONE

local function new(class, obj)
  local o = obj or {}
  setmetatable(o, class)
  class.__index = class
  return o
end

---@class Brick
---@field id integer
---@field min Pos3
---@field max Pos3
local Brick = {}
---@return Brick
function Brick:new(o)
  return new(Brick, o)
end

function Brick:__tostring()
  return string.format("%s-%s", tostring(self.min), tostring(self.max))
end

function Brick:height()
  return self.max.z - self.min.z + 1
end

---@param line string
local function read_brick(line)
  local _, _, x0, y0, z0, x1, y1, z1 = string.find(line, "(%d+),(%d+),(%d+)~(%d+),(%d+),(%d+)")
  return Brick:new {
    min = pos3(tonumber(x0) + 1, tonumber(y0) + 1, tonumber(z0)),
    max = pos3(tonumber(x1) + 1, tonumber(y1) + 1, tonumber(z1)),
  }
end

local function run(inputfile)
  print("Running " .. inputfile)
  local lines = files.lines_from(inputfile)

  local xmax = 0
  local ymax = 0
  ---@type Brick[]
  local bricks = {}
  for i, line in pairs(lines) do
    local b = read_brick(line)
    b.id = i
    table.insert(bricks, b)

    if xmax < b.max.x then xmax = b.max.x end
    if ymax < b.max.y then ymax = b.max.y end
  end

  table.sort(bricks, function(a, b)
    return a.min.z < b.min.z
  end)

  -- input shows no more than 10x10 for x,y
  local floor = grid.create(xmax, ymax, 0)
  local support = grid.create(xmax, ymax, nil)
  local supporting = {}
  local supported_by = {}

  for _, b in pairs(bricks) do
    supporting[b.id] = {}
    supported_by[b.id] = {}
    local bottom = 0
    for x = b.min.x, b.max.x do
      for y = b.min.y, b.max.y do
        if bottom < floor:at(x, y) then
          bottom = floor:at(x, y)
        end
      end
    end
    for x = b.min.x, b.max.x do
      for y = b.min.y, b.max.y do
        if floor:at(x, y) == bottom and support:at(x, y) then
          supporting[b.id][support:at(x, y).id] = true
          supported_by[support:at(x, y).id][b.id] = true
        end

        floor:set(x, y, bottom + b:height())
        support:set(x, y, b)
      end
    end
  end

  print(floor)

  local forbidden_to_disintegrate = {}
  for _, b in pairs(bricks) do
    local s = tables.keys(supporting[b.id])
    log.debug("brick " .. b.id .. " supported by: " .. tables.dump(s))

    log.debug("brick " .. b.id .. " supporting  : " .. tables.dump(tables.keys(supported_by[b.id])))

    if #s == 1 then
      forbidden_to_disintegrate[s[1]] = true
    end
  end

  print("Disintegratable without risk = " .. (#bricks - tables.length(forbidden_to_disintegrate)))

  local total_boom = 0
  local lookup = tables.lookup(bricks, function(b) return b.id end)

  for bid in pairs(forbidden_to_disintegrate) do
    local brick_to_disintegrate = lookup[bid]
    local nb_supports = {}
    for _, b in pairs(bricks) do
      nb_supports[b.id] = tables.length(supporting[b.id])
    end

    local disintegrated = { brick_to_disintegrate }
    local nb_disintegrated = 0
    while #disintegrated > 0 do
      local current = table.remove(disintegrated)
      for id in pairs(supported_by[current.id]) do
        nb_supports[id] = nb_supports[id] - 1
        if nb_supports[id] == 0 then
          nb_disintegrated = nb_disintegrated + 1
          table.insert(disintegrated, lookup[id])
        end
      end
    end
    log.debug("brick " .. brick_to_disintegrate.id .. " disintegrates " .. nb_disintegrated)
    total_boom = total_boom + nb_disintegrated
  end

  print("Disintegration = " .. total_boom)
end

--------------------------------------------------------------------------
--- TESTS
--------------------------------------------------------------------------

local assert = require('test').assert

local test = {}

function test.all()
  print("Running test")
  for name, fun in pairs(test) do
    if name ~= "all" and type(fun) == "function" then
      print("- test " .. name)
      fun()
    end
  end
  print("...Done")
end

test.all()
run("part1.txt")
run("input.txt")
