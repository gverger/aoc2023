local tables = require('tables')
local files = require('files')
local log = require('log')

log.LEVEL = log.LEVELS.DEBUG

local function new(class, obj)
  local o = obj or {}
  setmetatable(o, class)
  class.__index = class
  return o
end

local categories = { "x", "m", "a", "s" }

---@class Interval
---@field min integer
---@field max integer
local Interval = {}

---@return Interval
function Interval:new(o)
  return new(Interval, o)
end

---@return string
function Interval:__tostring()
  return "[" .. tostring(self.min) .. "; " .. tostring(self.max) .. "]"
end

function Interval:empty()
  return self.min > self.max
end

---@class PartSet
---@field x Interval
---@field m Interval
---@field a Interval
---@field s Interval
local PartSet = {}

---@return PartSet
function PartSet:new(o)
  return new(PartSet, o)
end

function PartSet:clone()
  local p = PartSet:new {}
  for _, c in pairs(categories) do
    p[c] = Interval:new { min = self[c].min, max = self[c].max }
  end
  return p
end

function PartSet:size()
  if self:empty() then return 0 end
  local size = 1

  for _, c in pairs(categories) do
    size = size * (self[c].max - self[c].min + 1)
  end
  return size
end

local function all_parts()
  local ps = PartSet:new {}
  for _, c in pairs(categories) do
    ps[c] = Interval:new { min = 1, max = 4000 }
  end
  return ps
end

---@return string
function PartSet:__tostring()
  local s = "{ "
  local sep = ""
  for _, c in pairs(categories) do
    s = s .. sep .. c .. " = " .. tostring(self[c])
    sep = ", "
  end
  return s .. " }"
end

function PartSet:empty()
  return tables.any(categories, function(c) return not self[c] or self[c]:empty() end)
end

---@class Part
---@field x integer
---@field m integer
---@field a integer
---@field s integer
local Part = {}

---@return Part
function Part:new(o)
  return new(Part, o)
end

---@return string
function Part:__tostring()
  local s = "{ "
  local sep = ""
  for _, c in pairs(categories) do
    s = s .. sep .. c .. " = " .. tostring(self[c])
    sep = ", "
  end
  return s .. " }"
end

local function read_part(line)
  local _, _, x, m, a, s = string.find(line, "x=(%d+),m=(%d+),a=(%d+),s=(%d+)")
  return Part:new { x = tonumber(x), m = tonumber(m), a = tonumber(a), s = tonumber(s) }
end

---@class Filter
---@field category string
---@field comparator string ">"|"<"
---@field threshold integer
---@field next string
local CmpFilter = {}

---@return Filter
function CmpFilter:new(o)
  return new(CmpFilter, o)
end

---@return string
function CmpFilter:__tostring()
  return tostring(self.category) ..
      " " .. tostring(self.comparator) .. " " .. tostring(self.threshold) .. " -> " .. tostring(self.next)
end

function CmpFilter:accept(part)
  if self.comparator == "<" then
    return part[self.category] < self.threshold
  else
    return part[self.category] > self.threshold
  end
end

---@param part_set PartSet
function CmpFilter:split(part_set)
  local accepted = part_set:clone()
  local rejected = part_set:clone()
  if self.comparator == "<" then
    accepted[self.category] = Interval:new { min = part_set[self.category].min, max = self.threshold - 1 }
    rejected[self.category] = Interval:new { min = self.threshold, max = part_set[self.category].max }
  else
    accepted[self.category] = Interval:new { min = self.threshold + 1, max = part_set[self.category].max }
    rejected[self.category] = Interval:new { min = part_set[self.category].min, max = self.threshold }
  end
  return accepted, rejected
end

---@class Redirect
---@field next string
local Redirect = {}

---@return Redirect
function Redirect:new(o)
  return new(Redirect, o)
end

---@return string
function Redirect:__tostring()
  return " |-> " .. tostring(self.next)
end

function Redirect:accept(_)
  return true
end

function Redirect:split(part_set)
  return part_set, PartSet:new { x = Interval:new { min = 0, max = 0 } }
end

---comment
---@param text string
---@return Filter | Redirect
local function read_filter(text)
  local first, last = table.unpack(tables.from_string(text, ":"))
  if not last then
    return Redirect:new { next = first }
  end

  local _, _, category, comparator, threshold, next = string.find(text, "([xmas])([<>])([0-9]+):([a-zA-z]+)")
  return CmpFilter:new {
    category = category,
    comparator = comparator,
    threshold = tonumber(threshold),
    next = next,
  }
end


---@class Rule
---@field name string
---@field filters Filter[]
local Rule = {}

---@return Rule
function Rule:new(o)
  return new(Rule, o)
end

---@return string
function Rule:__tostring()
  return tostring(self.name) .. ": " .. tables.join(tables.map(self.filters, function(f)
    return tostring(f)
  end), " | ")
end

---@param part Part
function Rule:next(part)
  for _, filter in pairs(self.filters) do
    if filter:accept(part) then
      return filter.next
    end
  end
  error("Can't filter for part = " .. part)
end

---@param part_set PartSet
function Rule:split(part_set)
  local part_sets = {}
  for _, filter in pairs(self.filters) do
    local accepted, rejected = filter:split(part_set)
    part_set = rejected
    if not accepted:empty() then
      table.insert(part_sets, { rule = filter.next, part_set = accepted })
    end
  end
  if not part_set:empty() then
    error("part_set should be empty")
  end
  return part_sets
end

local function read_rule(line)
  local _, _, name, filters_txt = string.find(line, "([a-z]+){(.+)}")
  local filter_strings = tables.from_string(filters_txt, ",")
  return Rule:new {
    name = name,
    filters = tables.map(filter_strings, function(txt) return read_filter(txt) end),
  }
end

---@class RuleEngine
---@field rules table<string, Rule>
local RuleEngine = {}

---@return RuleEngine
function RuleEngine:new(o)
  local re = new(RuleEngine, o)

  re.rules = re.rules or {}

  return re
end

---@param rule Rule
function RuleEngine:add(rule)
  self.rules[rule.name] = rule
end

local function is_terminal(rule_name)
  return rule_name == "A" or rule_name == "R"
end

function RuleEngine:accept(part)
  local current_rule_name = "in"

  while not is_terminal(current_rule_name) do
    local rule = self.rules[current_rule_name]
    if not rule then
      error("no rule named " .. current_rule_name)
    end

    current_rule_name = rule:next(part)
  end
  return current_rule_name == "A"
end

---@param part_set PartSet
---@param rule_name string
---@return integer
function RuleEngine:accept_set(part_set, rule_name)
  local open = { { part_set = part_set, rule = rule_name } }
  local number_accepted = 0
  while #open > 0 do
    local current = table.remove(open)
    if current.rule == "A" then
      number_accepted = number_accepted + current.part_set:size()
      goto continue
    end
    if current.rule == "R" then
      goto continue
    end

    local rule = self.rules[current.rule]
    if not rule then
      error("no rule named " .. current.rule)
    end

    for _, resp_set in pairs(rule:split(current.part_set)) do
      table.insert(open, resp_set)
    end

    ::continue::
  end

  return number_accepted
end

---@param part Part
---@return integer
local function part_score(part)
  return part.x + part.m + part.a + part.s
end

local function run(inputfile)
  print("Running " .. inputfile)
  local lines = files.lines_from(inputfile)

  local rules, parts = table.unpack(tables.split(lines, ""))

  local engine = RuleEngine:new()

  for _, r in pairs(rules) do
    engine:add(read_rule(r))
  end

  local score = 0
  for _, p in pairs(parts) do
    local part = read_part(p)
    local accepted = engine:accept(part)
    if accepted then
      score = score + part_score(part)
    end
  end

  print("Score = " .. score)


  print("All accepted sets = " .. engine:accept_set(all_parts(), "in"))
end

--------------------------------------------------------------------------
--- TESTS
--------------------------------------------------------------------------

local assert = require('test').assert

local test = {}

function test.read_filter()
  local txt = "a<2006:qkq"
  assert.equal(read_filter(txt), CmpFilter:new { category = "a", comparator = "<", threshold = 2006, next = "qkq" }, txt)
  assert.equal(read_filter("A"), Redirect:new { next = "A" }, "A")
end

function test.rule_accept()
  local p = Part:new { x = 787, m = 2655, a = 1222, s = 2876 }
  local low = CmpFilter:new { category = "a", comparator = "<", threshold = 1006, next = "qkq" }
  assert.equal(false, low:accept(p), "lower than low")

  local high = CmpFilter:new { category = "a", comparator = "<", threshold = 3006, next = "qkq" }
  assert.equal(true, high:accept(p), "lower than high")

  low = CmpFilter:new { category = "m", comparator = ">", threshold = 1006, next = "qkq" }
  assert.equal(true, low:accept(p), "greater than low")

  high = CmpFilter:new { category = "m", comparator = ">", threshold = 3006, next = "qkq" }
  assert.equal(false, high:accept(p), "greater than high")

  assert.equal(true, Redirect:new {}:accept(p), "redirect")
end

function test.read_rule()
  local line = "px{a<2006:qkq,m>2090:A,rfg}"
  local r, t = read_rule(line)
end

function test.read_part()
  local line = "{x=787,m=2655,a=1222,s=2876}"
  assert.equal(read_part(line), { x = 787, m = 2655, a = 1222, s = 2876 }, "read part")
end

function test.part_set()
  local set = all_parts()
  assert.equal(false, set:empty(), "all parts empty")

  set.x.min = 5000
  assert.equal(true, set:empty(), "all parts empty: x")
end

function test.split_rule()
  local line = "px{a<2006:qkq,m>2090:A,rfg}"
  local r = read_rule(line)
  local set = all_parts()
  local next = r:split(set)
  print(tables.dump(next))
end

function test.all()
  test.read_filter()
  test.read_part()

  test.rule_accept()
  test.read_rule()

  test.part_set()
  test.split_rule()
end

-- test.all()
run("part1.txt")
-- run("input.txt")
