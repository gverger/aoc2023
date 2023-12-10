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
---@return table<Coords,boolean>
local function in_the_loop(map)
  local current = map:find("S")

  local visited = {}
  setmetatable(visited, CoordTable)

  while current do
    local neighbours = current:neighbours(map)
    visited[current] = true
    current = nil
    for _, n in pairs(neighbours) do
      if not visited[n] then
        current = n
      end
    end
  end
  return visited
end

---@param map Map
---@param pipe Pipe
local function hidden_letter(map, pipe)
  local n = pipe:neighbours(map)

  local left = tables.any(n, function(p) return p.x == pipe.x - 1 end)
  local right = tables.any(n, function(p) return p.x == pipe.x + 1 end)
  local up = tables.any(n, function(p) return p.y == pipe.y - 1 end)
  local down = tables.any(n, function(p) return p.y == pipe.y + 1 end)

  if left and right then return "-" end
  if left and up then return "J" end
  if left and down then return "7" end
  if up and right then return "L" end
  if up and down then return "|" end
  if down and right then return "F" end

  return "#"
end

local function clean_map(map)
  local in_loop = in_the_loop(map)

  local m2 = Map:new {}

  for _, p in pairs(map.pipes) do
    if in_loop[p] then
      if p.letter == "S" then
        m2:add(Pipe:new { letter = hidden_letter(map, p), x = p.x, y = p.y })
      else
        m2:add(p)
      end
    else
      m2:add(Pipe:new { letter = ".", x = p.x, y = p.y })
    end
  end

  return m2
end

---@param map Map
local function loop_length(map)
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


---@param map Map
local function in_out(map, y)
  local res = {}
  local is_in = false
  local last_pipe = nil
  for x = 1, map.x_max do
    local pipe = map:at { x = x, y = y }
    if pipe.letter == "." then
      table.insert(res, is_in)
      goto continue
    end
    table.insert(res, false) -- on a pipe
    if pipe.letter == "|" then
      is_in = not is_in
    end
    if pipe.letter == "F" then
      if last_pipe ~= nil then print("error") end
      last_pipe = "bottom"
    end
    if pipe.letter == "L" then
      if last_pipe ~= nil then print("error") end
      last_pipe = "top"
    end

    if pipe.letter == "7" then
      if last_pipe == nil then print("error") end
      if last_pipe == "top" then
        is_in = not is_in
      end
      last_pipe = nil
    end

    if pipe.letter == "J" then
      if last_pipe == nil then print("error") end
      if last_pipe == "bottom" then
        is_in = not is_in
      end
      last_pipe = nil
    end

    ::continue::
  end

  return res
end

local function draw_in_out(map)
  local number_in = 0
  for j = 1, map.y_max do
    local ins = in_out(map, j)
    for i, is_in in pairs(ins) do
      if is_in then
        local p = map:at { x = i, y = j }
        p.letter = "I"
        number_in = number_in + 1
      end
    end
  end

  print(map)
  print("In = " .. number_in)
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

  local m = clean_map(map)
  draw_in_out(m)
end

--------------------------------------------------------------------------
--- TESTS
--------------------------------------------------------------------------
local assert = require('test').assert

local test = {}

function test.all()
end

test.all()
run("part1.txt")
run("part2.txt")
run("part3.txt")
run("part4.txt")
run("input.txt")
