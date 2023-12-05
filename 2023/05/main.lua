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

---@class Span
---@field first integer
---@field range integer
---@field last integer
Span = {}
function Span:__tostring()
  return "[" .. self.first .. ".." .. self.last .. "]"
end

function Span:new(o)
  local s = new(self, o)
  if s.range and not s.last then
    s.last = s.first + s.range - 1
  end
  if s.last and not s.range then
    s.range = s.last - s.first + 1
  end
  return s
end

function Span:move(offset)
  self.first = self.first + offset
  self.last = self.last + offset
end

---@class Shift
---@field src integer
---@field dst integer
---@field range integer
Shift = {}
function Shift.__tostring(shift)
  local from_range = Span:new { first = shift.src, range = shift.range }
  local to_range = Span:new { first = shift.dst, range = shift.range }
  local offset = shift.dst - shift.src
  if offset > 0 then offset = "+" .. offset end

  return tostring(from_range) .. " = " .. offset .. " => " .. tostring(to_range)
end

function Shift:new(o)
  return new(Shift, o)
end

---@return Span
function Shift:src_span()
  return Span:new { first = self.src, range = self.range }
end

---@return Span
function Shift:dst_span()
  return Span:new { first = self.dst, range = self.range }
end

---reads a shift from a text line
---@param line string
---@return Shift
local function read_shift(line)
  local dst, src, range = table.unpack(numbers_in(line))
  return Shift:new {
    src = src,
    dst = dst,
    range = range,
  }
end

---@class Mapping
---@field src string
---@field dst string
---@field shifts Shift[]
Mapping = {}
function Mapping:new(o)
  return new(Mapping, o)
end

---read a mapping from text lines
---@param lines string[]
---@return Mapping
local function read_mapping(lines)
  local m = {}

  local head = table.remove(lines, 1)
  m.src, m.dst = string.match(head, "([^-]*)[-]to[-]([^-]*) map:")

  m.shifts = tables.map(lines, function(line)
    return read_shift(line)
  end)

  return m
end

---@param span Span
---@param splitter Span
---@return Span[]
local function split_span(span, splitter)
  local spans = {}
  if span.first < splitter.first and splitter.first < span.last then
    table.insert(spans, Span:new { first = span.first, last = splitter.first - 1 })
    span = Span:new { first = splitter.first, last = span.last }
  end

  if span.first < splitter.last and splitter.last < span.last then
    table.insert(spans, Span:new { first = span.first, last = splitter.last })
    span = Span:new { first = splitter.last + 1, last = span.last }
  end

  if span.last >= span.first then
    table.insert(spans, span)
  end

  return spans
end

---maps the scan
---@param span Span
---@param map Mapping
---@return Span[]
local function map_span(span, map)
  if #map.shifts == 0 then
    return { span }
  end

  ---@type Span[]
  local splitted = { span }

  for _, shift in pairs(map.shifts) do
    ---@type Span[]
    local new_spans = {}
    for _, current_span in pairs(splitted) do
      for _, new_span in pairs(split_span(current_span, shift:src_span())) do
        table.insert(new_spans, new_span)
      end
    end
    splitted = new_spans
  end

  for _, r in pairs(splitted) do
    for _, c in pairs(map.shifts) do
      if r.first >= c.src and r.first < c.src + c.range then
        log.debug("apply " .. tables.dump(c.dst - c.src) .. " to " .. tostring(r))
        r:move(c.dst - c.src)
        log.debug(" => " .. tostring(r))
        break
      end
    end
  end

  return splitted
end

---Apply mappings to all spans
---@param spans Span[]
---@param map Mapping
---@return Span[]
local function map_spans(spans, map)
  local new_ranges = {}
  for _, span in pairs(spans) do
    for _, nr in pairs(map_span(span, map)) do
      table.insert(new_ranges, nr)
    end
  end
  return new_ranges
end

---comment
---@param spans Span[]
---@param mappings Mapping[]
---@return Span[]
local function apply_mappings(spans, mappings)
  local map_lookup = tables.lookup(mappings, function(map) return map.src end)

  local current_map = map_lookup["seed"]
  while current_map ~= nil do
    log.debug("Applying " .. current_map.src .. " to " .. current_map.dst)
    spans = map_spans(spans, current_map)
    log.debug(tables.join(spans))
    current_map = map_lookup[current_map.dst]
  end

  return spans
end


---@class Problem
---@field seeds Span[]
---@field maps Mapping[]

---reads an input files and create a problem for part 1
---@param input_file string
---@return Problem
local function read_file_part1(input_file)
  print("Input = " .. input_file)

  local lines = files.lines_from(input_file)
  local grouped = tables.split(lines, "")
  local first = table.remove(grouped, 1)
  local seeds = tables.map(numbers_in(first[1]), tonumber)

  local seeds_spans = {}
  for i = 1, #seeds do
    table.insert(seeds_spans, Span:new { first = seeds[i], range = 1 })
  end

  print("Seeds: " .. tables.join(seeds_spans, ", "))

  local maps = {}
  for _, group in pairs(grouped) do
    local map = read_mapping(group)
    table.insert(maps, map)
  end

  print("Mappings: " .. tables.join(tables.map(maps, function(m) return m.src .. "-to-" .. m.dst end), ", "))

  return {
    seeds = seeds_spans,
    maps = maps,
  }
end

---reads an input files and create a problem
---@param input_file string
---@return Problem
local function read_file_part2(input_file)
  print("Input = " .. input_file)

  local lines = files.lines_from(input_file)
  local grouped = tables.split(lines, "")
  local first = table.remove(grouped, 1)
  local seeds = tables.map(numbers_in(first[1]), tonumber)

  local seeds_spans = {}
  for i = 1, #seeds, 2 do
    table.insert(seeds_spans, Span:new { first = seeds[i], range = seeds[i + 1] })
  end

  print("Seeds: " .. tables.join(seeds_spans, ", "))

  local maps = {}
  for _, group in pairs(grouped) do
    local map = read_mapping(group)
    table.insert(maps, map)
  end

  print("Mappings: " .. tables.join(tables.map(maps, function(m) return m.src .. "-to-" .. m.dst end), ", "))

  return {
    seeds = seeds_spans,
    maps = maps,
  }
end

local function run_example()
  local filenames = {
    "part1.txt",
    "input.txt",
  }
  local part_readers = {
    ["Part 1"] = read_file_part1,
    ["Part 2"] = read_file_part2,
  }
  for name, read in pairs(part_readers) do
    print()
    print(name)
    for _, file in pairs(filenames) do
      local problem = read(file)

      local res_spans = apply_mappings(problem.seeds, problem.maps)

      print("Min = " .. tables.min(tables.map(res_spans, function(s) return s.first end), -1))
    end
  end
end

--------------------------------------------------------------------------
--- TESTS
--------------------------------------------------------------------------
local assert = require('test').assert

local test = {}

function test.read_shift()
  local line = "2 6 3"
  local shift = read_shift(line)

  assert.equal(shift, { dst = 2, src = 6, range = 3 }, "read_shift")
end

function test.read_mapping()
  local lines = { "humidity-to-location map:", "2 6 3", "3, 6, 9" }
  local mapping = read_mapping(lines)

  local expected = {
    dst = "location",
    src = "humidity",
    shifts = {
      { dst = 2, src = 6, range = 3 },
      { dst = 3, src = 6, range = 9 },
    }
  }

  assert.equal(mapping, expected, "read_mapping")
end

function test.new_span()
  assert.equal(Span:new { first = 3, range = 1 }, Span:new { first = 3, last = 3 })
  assert.equal(Span:new { first = 3, range = 4 }, Span:new { first = 3, last = 6 })
end

function test.map_span()
  local map = Mapping:new {
    dst = "location",
    src = "humidity",
    shifts = {
      Shift:new { dst = 2, src = 6, range = 3 },
    }
  }

  local before = Span:new { first = 2, range = 3 }
  assert.equal({ before }, map_span(before, map), "make_span before")

  local after = Span:new { first = 10, range = 3 }
  assert.equal({ after }, map_span(after, map), "make_span after")

  local intersect_lower = Span:new { first = 5, range = 3 }
  assert.equal({ Span:new { first = 5, range = 1 }, Span:new { first = 2, range = 2 } }, map_span(intersect_lower, map),
    "make_span intersect_lower")

  local intersect_upper = Span:new { first = 7, range = 4 }
  assert.equal({ Span:new { first = 3, range = 2 }, Span:new { first = 9, range = 2 } }, map_span(intersect_upper, map),
    "make_span intersect_lower")
end

function test.all()
  test.read_shift()
  test.read_mapping()
  test.new_span()
  test.map_span()
end

test.all()
run_example()
