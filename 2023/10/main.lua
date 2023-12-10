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

---@class Pipe
---@field letter string
---@field x integer
---@field y integer
local Pipe = {
  x = 0,
  y = 0,
  letter = ".",
}

---@return Pipe
function Pipe:new(o)
  return new(Pipe, o)
end

function Pipe:__tostring()
  return self.letter .. "(" .. self.x .. ", " .. self.y .. ")"
end

local pretty_letters = {
  ["-"] = "─",
  ["J"] = "╯",
  ["L"] = "╰",
  ["|"] = "│",
  ["F"] = "╭",
  ["7"] = "╮",
}
---@return string
function Pipe:pretty()
  return pretty_letters[self.letter] or self.letter
end

function Pipe:pointing_at_me(pipes, map)
  local res = {}
  for _, p in pairs(pipes) do
    local is_neighbour = function(c) return c.x == self.x and c.y == self.y end
    if tables.any(p:neighbours(map), is_neighbour) then
      table.insert(res, p)
    end
  end
  return res
end

---@class Coords
---@field x integer
---@field y integer
local Coords = {
  x = 0,
  y = 0,
}

function Pipe:neighbours(map)
  local up = map:at(Coords:new { x = self.x, y = self.y - 1 })
  local down = map:at(Coords:new { x = self.x, y = self.y + 1 })
  local left = map:at(Coords:new { x = self.x - 1, y = self.y })
  local right = map:at(Coords:new { x = self.x + 1, y = self.y })

  if self.letter == "-" then return { left, right } end
  if self.letter == "|" then return { up, down } end
  if self.letter == "J" then return { left, up } end
  if self.letter == "L" then return { up, right } end
  if self.letter == "7" then return { left, down } end
  if self.letter == "F" then return { down, right } end

  local possible_neighbours = { left, up, down, right }
  if self.letter == "S" then return self:pointing_at_me(possible_neighbours, map) end

  return {}
end

function Coords:new(o)
  return new(Coords, o)
end

---@return string
function Coords:__tostring()
  return "(" .. self.x .. ", " .. self.y .. ")"
end

---@class Map
---@field pipes table<Coords,Pipe>
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
  o.pipes = o.pipes or {}
  setmetatable(o.pipes, CoordTable)
  return new(Map, o)
end

function Map:at(coords)
  return self.pipes[coords]
end

---@param pipe Pipe
function Map:add(pipe)
  self.pipes[Coords:new { x = pipe.x, y = pipe.y }] = pipe
  if self.y_max < pipe.y then self.y_max = pipe.y end
  if self.x_max < pipe.x then self.x_max = pipe.x end
end

function Map:find(letter)
  for j = 1, self.y_max do
    for i = 1, self.x_max do
      local p = self:at(Coords:new { x = i, y = j })
      if p and p.letter == letter then
        return p
      end
    end
  end

  return nil
end

function Map:__tostring()
  local s = ""
  local sep = ""
  for j = 1, self.y_max do
    local line = ""
    for i = 1, self.x_max do
      line = line .. self.pipes[Coords:new { x = i, y = j }]:pretty()
    end
    s = s .. sep .. line
    sep = "\n"
  end
  return s
end

---@param map Map
function loop_length(map)
  local current = map:find("S")

  local length = 0
  local visited = {}
  setmetatable(visited, CoordTable)


  while current do
    local neighbours = current:neighbours(map)
    length = length + 1
    visited[current] = true
    current = nil
    for _, n in pairs(neighbours) do
      if not visited[n] then
        current = n
      end
    end
  end
  return length
end

local function run(inputfile)
  print("Running " .. inputfile)
  local lines = files.lines_from(inputfile)

  local map = Map:new {}

  for i, line in pairs(lines) do
    local chars = tables.chars_of(line)
    local pipes = tables.map(chars, function(l, j)
      return Pipe:new { letter = l, x = j, y = i }
    end)
    for _, p in pairs(pipes) do
      map:add(p)
    end
  end

  print(map)
  print("Length = " .. loop_length(map))
  print("Farthest = " .. loop_length(map) / 2)
end

--------------------------------------------------------------------------
--- TESTS
--------------------------------------------------------------------------
local assert = require('test').assert

local test = {}

function test.all()
end

test.all()
-- run("part1.txt")
-- run("part2.txt")
-- run("input.txt")

run("part4.txt")
