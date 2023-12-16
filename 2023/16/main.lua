local tables = require('tables')
local files = require('files')
local log = require('log')

log.LEVEL = log.LEVELS.NONE

local function new(class, obj)
  local o = obj or {}
  setmetatable(o, class)
  class.__index = class
  return o
end

---@class Coords
---@field x integer
---@field y integer
local Coords = {
  x = 0,
  y = 0,
}

---@return Coords
function Coords:new(o)
  return new(Coords, o)
end

local function position(x, y)
  return Coords:new { x = x, y = y }
end

---@return string
function Coords:__tostring()
  return "(" .. self.x .. ", " .. self.y .. ")"
end

---@class Ray
---@field pos Coords
---@field direction string
Ray = {}

---@return Ray
function Ray:new(o)
  return new(Ray, o)
end

local right = position(1, 0)
local left = position(-1, 0)
local up = position(0, -1)
local down = position(0, 1)


function Ray:__tostring()
  local dir = "?"
  if self.direction == right then
    dir = "->"
  elseif self.direction == left then
    dir = "<-"
  elseif self.direction == up then
    dir = "^"
  elseif self.direction == down then
    dir = "v"
  else
    error("unknown dir = " .. tables.dump { direction = self.direction, pos = self.pos })
  end
  return dir .. tostring(self.pos)
end

local keep_going = {
  [right] = right,
  [left] = left,
  [up] = up,
  [down] = down,
}

---@param ray Ray
---@return Coords[] the new directions
local function through_dot(ray)
  return { keep_going[ray.direction] }
end

local function through_hor_splitter(ray)
  if ray.direction == right or ray.direction == left then
    return { keep_going[ray.direction] }
  end

  return { left, right }
end

local function through_ver_splitter(ray)
  if ray.direction == up or ray.direction == down then
    return { keep_going[ray.direction] }
  end

  return { up, down }
end

-- turn when the mirror goes /
local turn_slash = {
  [right] = up,
  [left] = down,
  [up] = right,
  [down] = left,
}

local function through_slash_mirror(ray)
  return { turn_slash[ray.direction] }
end

-- turn when the mirror goes \
local turn_backslash = {
  [right] = down,
  [left] = up,
  [up] = left,
  [down] = right,
}

local function through_backslash_mirror(ray)
  return { turn_backslash[ray.direction] }
end

local moves = {
  ["."] = through_dot,
  ["-"] = through_hor_splitter,
  ["|"] = through_ver_splitter,
  ["/"] = through_slash_mirror,
  ["\\"] = through_backslash_mirror,
}

---comment
---@param ray Ray
---@param tile string
---@return Ray[]
local function move(ray, tile)
  local rays = {}
  for _, dir in pairs(moves[tile](ray)) do
    local r = Ray:new { direction = dir, pos = position(ray.pos.x + dir.x, ray.pos.y + dir.y) }
    table.insert(rays, r)
  end
  return rays
end

---@class Map
---@field tiles table<Coords, string>
---@field x_max integer
---@field y_max integer
local Map = {
  x_max = 0,
  y_max = 0,
}

CoordTable = {
  __index = function(table, key)
    return rawget(table, key.x .. "-" .. key.y)
  end,
  __newindex = function(table, key, value)
    rawset(table, key.x .. "-" .. key.y, value)
  end,
}

---@param o table
---@return Map
function Map:new(o)
  o.tiles = o.tiles or {}
  setmetatable(o.tiles, CoordTable)
  return new(Map, o)
end

---@param tile string
function Map:add(x, y, tile)
  self.tiles[position(x, y)] = tile
  if self.y_max < y then self.y_max = y end
  if self.x_max < x then self.x_max = x end
end

function Map:at(coords)
  return self.tiles[coords]
end

function Map:__tostring()
  local s = ""
  local sep = ""
  for j = 1, self.y_max do
    local line = ""
    for i = 1, self.x_max do
      line = line .. self.tiles[position(i, j)]
    end
    s = s .. sep .. line
    sep = "\n"
  end
  return s
end

local function dir_string(direction)
  if not direction or direction == 0 then
    return " "
  elseif direction == 1 then
    return "<"
  elseif direction == 2 then
    return "^"
  elseif direction == 4 then
    return ">"
  elseif direction == "8" then
    return "v"
  else
    return "#"
  end
end

local function energized_count(start, map)
  local visits = {}
  local all_dirs = { [left] = 1, [up] = 2, [right] = 4, [down] = 8 }
  local add_visit = function(x, y, direction)
    local key = x .. "-" .. y
    visits[key] = (visits[key] or 0) | all_dirs[direction]
  end
  local visited = function(x, y, direction)
    local key = x .. "-" .. y
    return (visits[key] or 0) & all_dirs[direction] > 0
  end

  local rays = { start }
  while #rays > 0 do
    local ray = table.remove(rays, #rays)
    if visited(ray.pos.x, ray.pos.y, ray.direction) then goto continue end

    add_visit(ray.pos.x, ray.pos.y, ray.direction)

    local new_rays = tables.filter(move(ray, map:at(ray.pos)), function(r)
      return map:at(r.pos) and not visited(r.pos.x, r.pos.y, r.direction)
    end)
    for _, r in pairs(new_rays) do
      table.insert(rays, r)
    end
    ::continue::
  end

  return tables.length(visits)
end

local function run(inputfile)
  print("Running " .. inputfile)
  local lines = files.lines_from(inputfile)

  local map = Map:new {}

  for i, line in pairs(lines) do
    local chars = tables.chars_of(line)
    for j, c in pairs(chars) do
      map:add(j, i, c)
    end
  end

  print("From top left: energy = " .. energized_count(Ray:new { pos = position(1, 1), direction = right }, map))

  local energy_max = 0
  for y = 1, map.y_max do
    energy_max = math.max(energy_max,
      energized_count(Ray:new { pos = position(1, y), direction = right }, map),
      energized_count(Ray:new { pos = position(map.x_max, y), direction = left }, map))
  end
  for x = 1, map.x_max do
    energy_max = math.max(energy_max,
      energized_count(Ray:new { pos = position(x, 1), direction = down }, map),
      energized_count(Ray:new { pos = position(x, map.y_max), direction = up }, map))
  end
  print("Max energy = " .. energy_max)
end

--------------------------------------------------------------------------
--- TESTS
--------------------------------------------------------------------------

local assert = require('test').assert

local test = {}

local list = require('list')

function test.all()
end

-- test.all()
run("part1.txt")
run("input.txt")
