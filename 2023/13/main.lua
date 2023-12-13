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

local function vertical_slices(lines)
  local slices = {}
  for i, line in pairs(lines) do
    local chars = tables.chars_of(line)
    for j, c in pairs(chars) do
      local value = 2 ^ (i - 1)
      if c == "." then value = 0 end
      slices[j] = (slices[j] or 0) + value
    end
  end
  return slices
end

local function horizontal_slices(lines)
  local slices = {}
  for i, line in pairs(lines) do
    local chars = tables.chars_of(line)
    for j, c in pairs(chars) do
      local value = 2 ^ (j - 1)
      if c == "." then value = 0 end
      slices[i] = (slices[i] or 0) + value
    end
  end
  return slices
end

---check that 2 numbers have a 1 bit difference
---@param a integer
---@param b integer
---@return boolean
local function differ_by_one_bit(a, b)
  local diff = a ~ b
  return 0.5 == (math.frexp(diff)) -- diff is a power of 2
end

local function is_symmetrical_at(index, slice, must_smudge)
  local smudged = false
  if not must_smudge then
    smudged = true
  end

  local i = index
  local j = index + 1
  while i >= 1 and j <= #slice do
    if smudged then
      if slice[i] ~= slice[j] then
        return false
      end
    else
      if slice[i] ~= slice[j] then
        if differ_by_one_bit(slice[i], slice[j]) then
          smudged = true
        else
          return false
        end
      end
    end

    i = i - 1
    j = j + 1
  end

  return smudged
end

--- [ 1, 2, 3, 3, 2 ] is symmetrical at index 3
---@param slice integer[]
---@param must_smudge boolean
---@return integer the index at which the symmetry is
local function symmetry(slice, must_smudge)
  for index = 1, #slice - 1 do
    if is_symmetrical_at(index, slice, must_smudge) then
      return index
    end
  end
  return -1
end

local function symmetry_score(g, allow_smudge)
  local hor = horizontal_slices(g)
  local sym = symmetry(hor, allow_smudge)
  if sym ~= -1 then
    return sym * 100
  end

  local ver = vertical_slices(g)
  sym = symmetry(ver, allow_smudge)
  if sym ~= -1 then
    return sym
  end

  error("no symmetry")
end

local function run(inputfile)
  print("Running " .. inputfile)
  local lines = files.lines_from(inputfile)

  local grids = tables.split(lines, "")
  local score_no_smudge = 0
  local score_with_smudge = 0
  for _, g in pairs(grids) do
    local sym_score = symmetry_score(g, false)
    score_no_smudge = score_no_smudge + sym_score

    sym_score = symmetry_score(g, true)
    score_with_smudge = score_with_smudge + sym_score
  end
  print("Score no smudge = " .. score_no_smudge)
  print("Score with smudge = " .. score_with_smudge)
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
