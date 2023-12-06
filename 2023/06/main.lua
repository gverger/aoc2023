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

---list the numbers in the string
---@param line string
---@return integer[]
local function numbers_in(line)
  local numbers = {}
  for n in string.gmatch(line, "(%d+)") do
    table.insert(numbers, tonumber(n))
  end
  return numbers
end

---@class Race
---@field time integer
---@field dist integer
Race = {}
function Race:__tostring()
  return string.format("( time = %d, dist = %d )", self.time, self.dist)
end

function Race:new(r)
  return new(Race, r)
end

---@class Problem
---@field races Race[]
Problem = {}
function Problem:__tostring()
  local s = ""
  local sep = ""
  for _, r in pairs(self.races) do
    s = s .. sep .. tostring(r)
    sep = "\n"
  end
  return s
end

---@return Problem
function Problem:new(p)
  return new(Problem, p)
end

---@param lines string[]
---@return Problem
function read_problem(lines)
  local times = numbers_in(lines[1])
  local distances = numbers_in(lines[2])

  local p = Problem:new()
  p.races = {}
  for i = 1, #times do
    local r = Race:new { time = times[i], dist = distances[i] }
    table.insert(p.races, r)
  end

  return p
end

---computes the roots
---@param race Race
local function compute_roots(race)
  --- equation attente + avance > distance
  --- equation x * 0 + (7 - x) * x >= 9
  ---          7x - x2 >= 9
  --- a = -1, b = 7, c = -9
  --- delta = b2 -4ac = time2 - 4 * distance
  local delta = race.time * race.time - 4 * race.dist
  if delta < 0 then
    error("delta < 0")
  end
  --- (-b - Vdelta) / 2a
  --- (-race.time - Vdelta) / -2
  --- (race.time + Vdelta) / 2
  local sol1 = math.ceil((race.time - math.sqrt(delta)) / 2)
  if (sol1 * ( race.time - sol1 ) == race.dist) then
    sol1 = sol1 + 1
  end
  local sol2 = math.floor((race.time + math.sqrt(delta)) / 2)
  if (sol2 * ( race.time - sol2 ) == race.dist) then
    sol2 = sol2 - 1
  end

  return { sol1, sol2 }
end

---@param race Race
local function nb_wins(race)
  local roots = compute_roots(race)
  return roots[2] - roots[1] + 1
end

local function run(filename)
  local lines = files.lines_from(filename)
  local p = read_problem(lines)
  print(p)
  local res = 1
  for _, race in pairs(p.races) do
    print(tables.join(compute_roots(race)) .. " = " .. nb_wins(race))
    res = res * nb_wins(race)
  end

  print("Res = " .. res)
end

--------------------------------------------------------------------------
--- TESTS
--------------------------------------------------------------------------
local assert = require('test').assert

local test = {}

function test.read_problem()
  local lines = {
    "Time:      7  15   30",
    "Distance:  9  40  200",
  }

  local p = read_problem(lines)
  print(p)
  for _, race in pairs(p.races) do
    print(tables.join(compute_roots(race)) .. " = " .. nb_wins(race))
  end
end

function test.all()
  test.read_problem()
end

-- test.all()
-- run("part1.txt")
-- run("input.txt")
-- run("part2.txt")
run("input2.txt")
