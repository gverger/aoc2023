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

local function roll_north(grid)
  local nb_lines = #grid
  local nb_cols = #grid[1]

  local new_grid = {}
  for i = 1, nb_lines do
    local line = {}
    for j = 1, nb_cols do
      table.insert(line, ".")
    end
    table.insert(new_grid, line)
  end

  local next_position = {}
  for i = 1, nb_cols do
    next_position[i] = nb_lines
  end

  for lidx, line in pairs(grid) do
    for cidx, c in pairs(line) do
      if c == "#" then
        next_position[cidx] = nb_lines - lidx
        new_grid[lidx][cidx] = "#"
      else
        if c == "O" then
          new_grid[nb_lines + 1 - next_position[cidx]][cidx] = "O"
          next_position[cidx] = (next_position[cidx] or 0) - 1
        end
      end
    end
  end
  return new_grid
end

local function roll_south(grid)
  local nb_lines = #grid
  local nb_cols = #grid[1]

  local new_grid = {}
  for i = 1, nb_lines do
    local line = {}
    for j = 1, nb_cols do
      table.insert(line, ".")
    end
    table.insert(new_grid, line)
  end


  local next_position = {}
  for i = 1, nb_cols do
    next_position[i] = nb_lines
  end

  for lidx = nb_lines, 1, -1 do
    for cidx = 1, nb_cols do
      local c = grid[lidx][cidx]
      if c == "#" then
        next_position[cidx] = lidx - 1
        new_grid[lidx][cidx] = "#"
      else
        if c == "O" then
          new_grid[next_position[cidx]][cidx] = "O"
          next_position[cidx] = next_position[cidx] - 1
        end
      end
    end
  end
  return new_grid
end

local function roll_west(grid)
  local nb_lines = #grid
  local nb_cols = #grid[1]

  local new_grid = {}
  for i = 1, nb_lines do
    local line = {}
    for j = 1, nb_cols do
      table.insert(line, ".")
    end
    table.insert(new_grid, line)
  end


  local next_position = {}
  for i = 1, nb_lines do
    next_position[i] = 1
  end

  for lidx, line in pairs(grid) do
    for cidx = 1, nb_cols do
      local c = line[cidx]
      if c == "#" then
        next_position[lidx] = cidx + 1
        new_grid[lidx][cidx] = "#"
      else
        if c == "O" then
          new_grid[lidx][next_position[lidx]] = "O"
          next_position[lidx] = next_position[lidx] + 1
        end
      end
    end
  end
  return new_grid
end

local function roll_east(grid)
  local nb_lines = #grid
  local nb_cols = #grid[1]

  local new_grid = {}
  for i = 1, nb_lines do
    local line = {}
    for j = 1, nb_cols do
      table.insert(line, ".")
    end
    table.insert(new_grid, line)
  end


  local next_position = {}
  for i = 1, nb_lines do
    next_position[i] = nb_cols
  end

  for lidx, line in pairs(grid) do
    for cidx = nb_cols, 1, -1 do
      local c = line[cidx]
      if c == "#" then
        next_position[lidx] = cidx - 1
        new_grid[lidx][cidx] = "#"
      else
        if c == "O" then
          new_grid[lidx][next_position[lidx]] = "O"
          next_position[lidx] = next_position[lidx] - 1
        end
      end
    end
  end
  return new_grid
end

local function id(grid)
  local n = 0
  for i, line in pairs(grid) do
    local l = 0
    for j, c in pairs(line) do
      if c == "O" then
        l = l + math.pow(2, j % 32)
      end
    end
    n = n ~ l
  end
  return n
end

local function score(grid)
  local nb_lines = #grid

  local s = 0

  for i, line in pairs(grid) do
    for j, c in pairs(line) do
      if c == "O" then
        s = s + nb_lines + 1 - i
      end
    end
  end
  return s
end

local function cycle(scores, next_score)
  for i = #scores, 1, -1 do
    if scores[i] == next_score then
      return #scores + 1 - i
    end
  end
  return -1
end

local function run(inputfile)
  print("Running " .. inputfile)
  local lines = files.lines_from(inputfile)

  local grid = tables.map(lines, function(line)
    return tables.chars_of(line)
  end)
  local north = roll_north(grid)
  print("Score = " .. score(north))

  -- print("\nNorth")
  -- local rolled = roll_north(grid)
  -- for _, line in pairs(rolled) do
  --   print(tables.join(line, ""))
  -- end
  -- print("\nSouth")
  -- rolled = roll_south(grid)
  -- for _, line in pairs(rolled) do
  --   print(tables.join(line, ""))
  -- end
  -- print("\nEast")
  -- rolled = roll_east(grid)
  -- for _, line in pairs(rolled) do
  --   print(tables.join(line, ""))
  -- end
  -- print("\nWest")
  -- rolled = roll_west(grid)
  -- for _, line in pairs(rolled) do
  --   print(tables.join(line, ""))
  -- end

  local global_score = 0
  local nb_cycles = 0
  local ids = {}
  local scores = {}
  for i = 1, 1000000000 do
    grid = roll_north(grid)
    grid = roll_west(grid)
    grid = roll_south(grid)
    grid = roll_east(grid)
    local current = id(grid)
    -- print("s = " .. current)
    local cycl = cycle(ids, current)
    local s = score(grid)

    if cycl ~= -1 and cycle(scores, s) == cycl then
      local remaining = (1000000000 - i) % cycl

      print("score = " .. scores[i - cycl + remaining])
    end

    table.insert(scores, s)
    table.insert(ids, current)

    -- print(s)
    -- if s == global_score then
    --   nb_cycles = nb_cycles + 1
    --   print("score = " .. global_score)
    --   if nb_cycles >= 100 then
    --     break
    --   end
    -- else
    --   nb_cycles = 0
    -- end
    -- global_score = s
  end

  print("score = " .. global_score)
end

--------------------------------------------------------------------------
--- TESTS
--------------------------------------------------------------------------

local assert = require('test').assert

local test = {}

local list = require('list')

function test.all()
  local next = function(n) if n ~= 8 then return n + 1 else return 5 end end
  local equal = function(a, b) return a == b end
  local cycle_length, start_point = list.cycle(0, next, equal)

  local current = 0
  local s = ""
  local sep = ""
  for i = 1, start_point do
    s = s .. sep .. current
    current = next(current)
    sep = " "
  end

  s = s .. " ["
  for i = 1, cycle_length do
    s = s .. sep .. current
    current = next(current)
  end
  s = s .. " ] "
  print(s)
end

test.all()
-- run("part1.txt")
-- run("input.txt")
