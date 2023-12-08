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

---@class Node
---@field name string
---@field left string
---@field right string
local Node = {}

function Node:new(o)
  o = o or {}
  return new(Node, o)
end

function Node:__tostring()
  return string.format("%s = (left = %s, right = %s)", self.name, self.left, self.right)
end

---@return Node
local function read_node(line)
  local name, left, right = string.match(line, "([0-9A-Z]+) = %(([0-9A-Z]+), ([0-9A-Z]+)%)")
  return Node:new { name = name, left = left, right = right }
end

---@class Network
---@field nodes table<string, Node>
local Network = {}

---@return Network
function Network:new(o)
  o = o or {}
  o.nodes = o.nodes or {}

  return new(Network, o)
end

function Network:node(name)
  return self.nodes[name]
end

function Network:__tostring()
  local s = ""
  local sep = ""
  for _, node in pairs(self.nodes) do
    s = s .. sep .. tostring(node)
    sep = "\n"
  end
  return s
end

---@class Problem
---@field instructions string
---@field map Network
local Problem = {}

function Problem:new(o)
  o = o or {}
  return new(Problem, o)
end

local function read_problem(lines)
  local p = Problem:new()

  p.instructions = lines[1]
  table.remove(lines, 1)
  table.remove(lines, 1)

  p.map = Network:new()

  for _, line in pairs(lines) do
    local n = read_node(line)
    p.map.nodes[n.name] = n
  end
  return p
end

---@class Walker
---@field instructions string
---@field network Network
---@field current_node string
---@field goal string
---@field instruction_idx integer
local Walker = {}

function Walker:new(o)
  o = new(Walker, o)
  if not o.done then
    o.done = function(_)
      return true
    end
  end

  if not o.current_node then
    o.current_node = "AAA"
  end

  o.instruction_idx = 1

  return o
end

function Walker:walk()
  local inst = self:next_instruction()
  local node = self.network:node(self.current_node)
  if inst == "L" then
    self.current_node = node.left
  else
    self.current_node = node.right
  end
end

function Walker:next_instruction()
  local inst = string.sub(self.instructions, self.instruction_idx, self.instruction_idx)
  self.instruction_idx = self.instruction_idx % #self.instructions + 1
  return inst
end

local function run_part1(filename)
  print("Running " .. filename)
  local lines = files.lines_from(filename)
  local p = read_problem(lines)

  print(p.instructions)
  print(p.map)

  local w = Walker:new {
    instructions = p.instructions,
    network = p.map,
    done = function(w)
      return w.current_node == "ZZZ"
    end,
  }

  local steps = 0
  while not w:done() do
    w:walk()
    steps = steps + 1
  end
  print("Steps = " .. steps)
end

local function nth_char(txt, n)
  return string.sub(txt, n, n)
end

---@param numbers integer[]
---@return number
local function least_common_denominator(numbers)
  local div = 2
  local lcd = 1
  while #numbers >= 1 do
    local at_least_one_divided = false
    local divided_numbers = {}
    for _, n in pairs(numbers) do
      if n % div == 0 then
        at_least_one_divided = true
        if n / div > 1 then
          table.insert(divided_numbers, n / div)
        end
      else
        table.insert(divided_numbers, n)
      end
    end
    numbers = divided_numbers
    if at_least_one_divided then
      print("DIV = " .. div)
      print(tables.dump(numbers))
      lcd = lcd * div
    else
      div = div + 1
    end
  end
  return lcd
end

local function run_part2(filename)
  print("Running " .. filename)
  local lines = files.lines_from(filename)
  local p = read_problem(lines)

  print(p.instructions)
  print(p.map)

  local walkers = {}
  for n in pairs(p.map.nodes) do
    if nth_char(n, #n) == "A" then
      print("START = " .. n)
      local w = Walker:new {
        loop = {},
        current_node = n,
        instructions = p.instructions,
        network = p.map,
        done = function(w)
          return nth_char(w.current_node, #w.current_node) == "Z"
        end,
      }
      table.insert(walkers, w)
    end
  end

  local cycles = {}
  for _, w in pairs(walkers) do
    local cycle_length = 0
    while not w:done() do
      w:walk()
      cycle_length = cycle_length + 1
    end
    table.insert(cycles, cycle_length)
  end

  print(tables.dump(cycles))
  print("LCD = " .. least_common_denominator(cycles))


  --
  --
  -- local steps = 0
  -- while tables.any(walkers, function(w) return not w:done() end) do
  --   for _, w in pairs(walkers) do
  --     w:walk()
  --     print(w.current_node)
  --   end
  --   steps = steps + 1
  -- end
  -- print("Steps = " .. steps)
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
-- run("ex2.txt")
-- run_part1("input.txt")
-- run_part2("part2.txt")
run_part2("input.txt")
