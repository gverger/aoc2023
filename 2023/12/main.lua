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

local function run(inputfile)
  print("Running " .. inputfile)
  local lines = files.lines_from(inputfile)
end

---@class Chunk
---@field start integer
---@field stop integer
---@field operationa_springs integer[] indices of the operation springs in this chunk
local Chunk = {}

---@return Chunk
function Chunk:new(o)
  local c = new(Chunk, o)
  c.operationa_springs = c.operationa_springs or {}
  return c
end

---@return string
function Chunk:__tostring()
  return "[" .. self.start .. "-" .. self.stop .. "]"
end

---@class Row
---@field chunks Chunk[]
---@field operational_spring_lengths integer[]
local Row = {}

---@return Row
function Row:new(o)
  local r = new(Row, o)
  r.chunks = r.chunks or {}
  r.operational_spring_lengths = r.operational_spring_lengths or {}
  return r
end

---@return string
function Row:__tostring()
  local chars = {}
  local max = 0
  for _, c in pairs(self.chunks) do
    for i = c.start, c.stop do
      chars[i] = "?"
    end

    for _, i in pairs(c.operationa_springs) do
      chars[i + c.start] = "#"
    end
    max = c.stop
  end

  for i = 1, max do
    chars[i] = chars[i] or "."
  end

  return tables.join(chars, "") .. " " .. tables.join(self.operational_spring_lengths, " ")
end

---@param line string
---@return Row
local function read_row(line)
  local r = Row:new()
  local current_chunk = nil
  local index = 0
  local observation, operational_spring_lengths = table.unpack(tables.from_string(line, " "))

  r.operational_spring_lengths = tables.map(tables.from_string(operational_spring_lengths, ","), function (n)
    return tonumber(n)
  end)

  for c in string.gmatch(observation, ".") do
    index = index + 1
    if not current_chunk and c == "." then goto continue end

    if not current_chunk then
      current_chunk = Chunk:new { start = index }
    end

    if c == "." then
      table.insert(r.chunks, current_chunk)
      current_chunk = nil
      goto continue
    end

    if c == "#" then
      table.insert(current_chunk.operationa_springs, index - current_chunk.start)
    end

    current_chunk.stop = index

    ::continue::
  end

  if current_chunk then
    table.insert(r.chunks, current_chunk)
  end

  return r
end

--------------------------------------------------------------------------
--- TESTS
--------------------------------------------------------------------------

local assert = require('test').assert

local test = {}

function test.one_row()
  local line = "???.### 1,1,3"

  local r = read_row(line)

  print(r)
end

function test.all()
  test.one_row()
end

test.all()
-- run("part1.txt")
-- run("input.txt")
