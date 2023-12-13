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

---@class Chunk
---@field start integer
---@field stop integer
---@field mandatory_springs integer[] indices of the operation springs in this chunk
---@field no_start integer[]
---@field no_stop integer[]
local Chunk = {}

---@return Chunk
function Chunk:new(o)
  local c = new(Chunk, o)
  c.mandatory_springs = c.mandatory_springs or {}
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

    for _, i in pairs(c.mandatory_springs) do
      chars[i + c.start] = "#"
    end
    max = c.stop
  end

  for i = 1, max do
    chars[i] = chars[i] or "."
  end

  local indices = ""
  for i = 1, max do
    indices = indices .. (i % 10)
  end

  return tables.join(chars, "") .. " " .. tables.join(self.operational_spring_lengths, " ") .. "\n" .. indices
end

---@class ChunkVar
---@field chunk_id integer
---@field nb_springs integer
---@field domain integer[]
---@field is_set boolean
local ChunkVar = {}


---@return ChunkVar
function ChunkVar:new(o)
  local c = new(ChunkVar, o)
  c.domain = c.domain or {}
  c.is_set = tables.length(c.domain) == 1
  return c
end

---@class Problem
---@field row Row
---@field vars ChunkVar[]

local Problem = {}

---@return Problem
function Problem:new(o)
  local p = new(Problem, o)
  p.vars = p.vars or {}
  return p
end

---@param row Row
---@return Problem
local function create_problem(row)
  local p = Problem:new()
  p.row = row

  local chunk_id = 1

  for _, l in pairs(row.operational_spring_lengths) do
    log.debug("chunk " .. chunk_id .. " l = " .. l)
    local d = {}
    for _, c in pairs(row.chunks) do
      if c.stop - c.start + 1 < l then
        log.debug("chunk " .. tostring(c) .. " not large enough")
        goto continue
      end

      log.debug("chunk " .. tostring(c) .. "ok")

      for i = c.start, c.stop - l + 1 do
        for _, s in pairs(c.mandatory_springs) do
          local mandatory = c.start + s
          if mandatory + 1 == i then
            log.debug("cannot start at i = " .. i .. " mandatory = " .. mandatory)
            goto next_value
          end
          if mandatory - 1 == i + l - 1 then
            log.debug("cannot end at i = " .. i .. " mandatory = " .. mandatory)
            goto next_value
          end
        end

        table.insert(d, i)

        ::next_value::
      end


      ::continue::
    end
    local var = ChunkVar:new { chunk_id = chunk_id, nb_springs = l, domain = d }
    log.debug("new var " .. tostring(var))
    table.insert(p.vars, var)
    chunk_id = chunk_id + 1
  end

  return p
end

---@return string
function ChunkVar:__tostring()
  if #self.domain == 1 then
    return string.format("%s = %d", self.chunk_id, self.domain[1])
  else
    return string.format("%s in %s", self.chunk_id, tables.dump(self.domain))
  end
end

---@param p Problem
local function propagate_min(p)
  for i = 2, #p.vars do
    local var = p.vars[i]
    local pred = p.vars[i - 1]
    log.debug("pred = " .. tostring(pred))
    log.debug("var = " .. tostring(var))

    local new_min = pred.domain[1] + pred.nb_springs + 1
    if var.domain[#var.domain] < new_min then
      error("propagate_min")
    end
    while var.domain[1] < new_min do
      table.remove(var.domain, 1)
    end
  end
end

---@param p Problem
local function propagate_max(p)
  for i = #p.vars - 1, 1, -1 do
    local var = p.vars[i]
    local succ = p.vars[i + 1]

    local new_max = succ.domain[#succ.domain] - 2
    if var.domain[1] > new_max then
      error("propagate_max")
    end
    while var.domain[#var.domain] + var.nb_springs - 1 > new_max do
      table.remove(var.domain, #var.domain)
    end
  end
end


-- ?###????
-- length = 3, start = 2 6 7
-- mandatory = 2 3 4
---@param p Problem
local function ensure_mandatory(p)
  local vidx = 1
  local var = p.vars[vidx]
  local changed = false
  for _, c in pairs(p.row.chunks) do
    for _, s in pairs(c.mandatory_springs) do
      local new_max = c.start + s
      while var.domain[#var.domain] + var.nb_springs - 1 < new_max do
        vidx = vidx + 1
        var = p.vars[vidx]
      end

      if var.domain[1] > new_max then
        error("ensure_mandatory")
      end
      while var.domain[#var.domain] > new_max do
        table.remove(var.domain, #var.domain)
        changed = true
      end
    end
  end
  if changed then
    propagate_max(p)
  end
end

---@class Placed
---@field start integer
---@field stop integer
local Placed = {}

---@return Placed
function Placed:new(o)
  return new(Placed, o)
end

---@param hist Placed[]
local function placed(hist)
  local chars = {}
  local max = 0
  for _, c in pairs(hist) do
    for i = c.start, c.stop do
      chars[i] = "X"
    end
    max = c.stop
  end

  for i = 1, max do
    chars[i] = chars[i] or "."
  end

  local indices = ""
  for i = 1, max do
    indices = indices .. (i % 10)
  end
  return tables.join(chars, "")
end

---@param row Row
---@param vars ChunkVar[]
---@param current integer
---@return integer
local function nb_branches(row, vars, vari, current, hist, cache)
  if not cache then
    cache = {}
  end

  if not cache[vari] then
    cache[vari] = {}
  end

  if not hist then
    hist = {}
  end

  local next_mandatory = nil
  for _, chunk in pairs(row.chunks) do
    for _, s in pairs(chunk.mandatory_springs) do
      local mandatory = chunk.start + s
      if mandatory >= current then
        next_mandatory = mandatory
        goto mandatory_found
      end
    end
  end
  ::mandatory_found::

  if vari > #vars then
    if next_mandatory then
      return 0
    end
    -- print(placed(hist))
    return 1
  end

  local v = vars[vari]

  local s = 0
  for _, value in pairs(v.domain) do
    if value >= current and (not next_mandatory or value <= next_mandatory) then
      local h = {}
      -- for _, old in ipairs(hist) do
      --   table.insert(h, old)
      -- end
      -- table.insert(h, Placed:new { start = value, stop = value + v.nb_springs - 1 })

      if not cache[vari][value] then
        cache[vari][value] = nb_branches(row, vars, vari + 1, value + v.nb_springs + 1, h, cache)
      end
      s = s + cache[vari][value]
    end
  end
  return s
end

---@param line string
---@return Row
local function read_row(line)
  local r = Row:new()
  local current_chunk = nil
  local index = 0
  local observation, operational_spring_lengths = table.unpack(tables.from_string(line, " "))

  r.operational_spring_lengths = tables.map(tables.from_string(operational_spring_lengths, ","), function(n)
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
      table.insert(current_chunk.mandatory_springs, index - current_chunk.start)
    end

    current_chunk.stop = index

    ::continue::
  end

  if current_chunk then
    table.insert(r.chunks, current_chunk)
  end

  return r
end

local function unfold(line)
  local line1, line2 = table.unpack(tables.from_string(line, " "))
  local s1 = ""
  local sep1 = ""
  for i = 1, 5 do
    s1 = s1 .. sep1 .. line1
    sep1 = "?"
  end

  local s2 = ""
  local sep2 = ""
  for i = 1, 5 do
    s2 = s2 .. sep2 .. line2
    sep2 = ","
  end

  return s1 .. " " .. s2
end

local function run(inputfile)
  print("Running " .. inputfile)
  local lines = files.lines_from(inputfile)

  local nbs = 0
  for _, line in pairs(lines) do
    line = unfold(line)
    local row = read_row(line)
    -- print(row)
    local p = create_problem(row)
    propagate_min(p)
    propagate_max(p)
    ensure_mandatory(p)
    -- print(tables.dump(p.vars))

    local nb = nb_branches(p.row, p.vars, 1, 1)
    -- print(nb)
    nbs = nbs + nb
  end

  print("Sum = " .. nbs)
end

--------------------------------------------------------------------------
--- TESTS
--------------------------------------------------------------------------

local assert = require('test').assert

local test = {}

function test.one_row()
  local line = "???.### 1,1,3"

  local r = read_row(line)

  assert.equal(tostring(r), "???.### 1 1 3\n1234567")
end

function test.create_problem()
  local test_cases = {
    -- { line = "???.### 1,1,3" },
    -- { line = "????.######..#####. 1,6,5" },
    -- { line = "?###???????? 3,2,1" },
    -- { line = "???#?????????# 1,6,4" },
    { line = "#????????.#??.? 1,3,1,1,1" },
  }

  for _, tc in pairs(test_cases) do
    local r = read_row(tc.line)
    print(r)
    local p = create_problem(r)
    propagate_min(p)
    propagate_max(p)
    ensure_mandatory(p)
    print(tables.dump(p.vars))
    print(nb_branches(p.row, p.vars, 1, 1))
  end
end

function test.all()
  test.one_row()
  test.create_problem()
end

test.all()
run("part1.txt")
run("input.txt")
