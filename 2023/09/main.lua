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

local function numbers_in(line)
  return tables.map(tables.from_string(line, " "), function(n) return tonumber(n) end)
end

---@param numbers integer[]
---@return integer[]
local function next_coeffs(numbers)
  local coeffs = {}
  for i = 2, #numbers do
    table.insert(coeffs, numbers[i] - numbers[i - 1])
  end
  return coeffs
end

---@param numbers integer[]
---@return integer
local function next_value(numbers)
  if tables.all(numbers, function(v) return v == 0 end) then
    return 0
  end
  local coeffs = next_coeffs(numbers)
  return numbers[#numbers] + next_value(coeffs)
end

local function run(filename)
  print("Running " .. filename)
  local lines = files.lines_from(filename)

  local part1 = 0
  local part2 = 0
  for _, line in pairs(lines) do
    local numbers = numbers_in(line)
    part1 = part1 + next_value(numbers)
    part2 = part2 + next_value(tables.reverse(numbers))
  end

  print("sum part 1 = " .. part1)
  print("sum part 2 = " .. part2)
end

--------------------------------------------------------------------------
--- TESTS
--------------------------------------------------------------------------
local assert = require('test').assert

local test = {}

function test.next_value()
  assert.equal(18, next_value { 0, 3, 6, 9, 12, 15 }, "next_value")
  assert.equal(68, next_value { 10, 13, 16, 21, 30, 45 }, "next_value")
end

function test.next_coeffs()
  assert.equal({ 3, 3, 3, 3, 3 }, next_coeffs { 0, 3, 6, 9, 12, 15 }, "next_coeffs")
  assert.equal({ 3, 3, 5, 9, 15 }, next_coeffs { 10, 13, 16, 21, 30, 45 }, "next_coeffs")
end

function test.all()
  test.next_coeffs()
  test.next_value()
end

test.all()
run("part1.txt")
run("input.txt")
