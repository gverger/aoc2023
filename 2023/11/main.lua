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

---@param lines string[]
local function vertical_count(lines)
  local vertical = {}
  for _, line in pairs(lines) do
    local chars = tables.chars_of(line)
    table.insert(vertical, tables.count(chars, function(c) return c == "#" end))
  end
  return vertical
end

---@param lines string[]
local function horizontal_count(lines)
  local horizontal = {}

  for _, line in pairs(lines) do
    local chars = tables.chars_of(line)
    for i, value in pairs(chars) do
      local inc = 0
      if value == "#" then
        inc = 1
      end
      horizontal[i] = (horizontal[i] or 0) + inc
    end
  end
  return horizontal
end

---@param projected_galaxies integer[] the number of galaxies projected on an axis
---@param expansion_rate integer
local function distances(projected_galaxies, expansion_rate)
  local number_values = tables.sum(projected_galaxies)
  local galaxies_encountered = 0

  local sum = 0
  for _, galaxies in pairs(projected_galaxies) do
    local expanded = 1
    if galaxies == 0 then
      expanded = expansion_rate
    end
    local inc = galaxies_encountered * (number_values - galaxies_encountered) * expanded
    sum = sum + inc
    galaxies_encountered = galaxies_encountered + galaxies
  end

  return sum
end


local function run(inputfile)
  print("Running " .. inputfile)
  local lines = files.lines_from(inputfile)

  local vertical = vertical_count(lines)
  local horizontal = horizontal_count(lines)

  local part1_expansion = 2
  local sum_of_distances1 = distances(horizontal, part1_expansion) + distances(vertical, part1_expansion)
  print("Part 1 distances = " .. sum_of_distances1)

  local part2_expansion = 1000000
  local sum_of_distances2 = distances(horizontal, part2_expansion) + distances(vertical, part2_expansion)
  print("Part 2 distances = " .. sum_of_distances2)
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
run("input.txt")
