local tables = require('tables')
local files = require('files')
local log = require('log')
local grid = require('grid')

log.LEVEL = log.LEVELS.DEBUG

local function new(class, obj)
  local o = obj or {}
  setmetatable(o, class)
  class.__index = class
  return o
end

---@class Position
---@field x integer
---@field y integer

local function vector(x, y)
  return { x = x, y = y }
end

local function add_vecs(vec1, vec2)
  return vector(vec1.x + vec2.x, vec1.y + vec2.y)
end

local function mult_vec(scalar, vec)
  return vector(scalar * vec.x, scalar * vec.y)
end

local direction_vec = {
  ["R"] = vector(1, 0),
  ["L"] = vector(-1, 0),
  ["U"] = vector(0, -1),
  ["D"] = vector(0, 1),
}

local function read_map(lines)
  local max = vector(1, 1)
  local min = vector(1, 1)
  local current_pos = vector(1, 1)

  for _, line in ipairs(lines) do
    local dir, length = table.unpack(tables.from_string(line, " "))
    current_pos = add_vecs(mult_vec(tonumber(length), direction_vec[dir]), current_pos)
    if current_pos.x < min.x then min.x = current_pos.x end
    if current_pos.y < min.y then min.y = current_pos.y end
    if current_pos.x > max.x then max.x = current_pos.x end
    if current_pos.y > max.y then max.y = current_pos.y end
  end

  print("min = " .. min.x .. "," .. min.y)
  print("max = " .. max.x .. "," .. max.y)

  local map = grid.create(max.x - min.x + 1, max.y - min.y + 1, ".")
  current_pos = vector(2 - min.x, 2 - min.y)
  map:set(current_pos.x, current_pos.y, "#")
  for _, line in ipairs(lines) do
    local dir, l = table.unpack(tables.from_string(line, " "))
    local length = tonumber(l)
    for i = 1, length do
      current_pos = add_vecs(direction_vec[dir], current_pos)
      map:set(current_pos.x, current_pos.y, "#")
    end
  end

  return map
end

---@param map Grid
local function in_out(map, y)
  local res = {}
  local is_in = false
  for x = 1, map.xmax do
    local tile = map:at(x, y)
    if map:at(x - 1, y) == "#" and map:at(x - 1, y - 1) == "#" then
      is_in = not is_in
    end

    if tile == "." then
      table.insert(res, is_in)
    else
      table.insert(res, true)
    end
  end

  return res
end

local function draw_in_out(map)
  local number_in = 0
  for j = 1, map.ymax do
    local ins = in_out(map, j)
    for i, is_in in pairs(ins) do
      if is_in then
        if map:at(i, j) == "." then
          map:set(i, j, "0")
        end
        number_in = number_in + 1
      end
    end
  end

  print(map)
  print("In = " .. number_in)
end

local function shoelace_area(points)
  local area = 0
  for i = 1, #points - 1 do
    local p1 = points[i]
    local p2 = points[i + 1]
    area = area + p1.x * p2.y - p1.y * p2.x
  end
  return math.abs(area) / 2
end

local function read_part1(line)
  local dir, length = table.unpack(tables.from_string(line, " "))
  return dir, tonumber(length)
end

local function read_part2(line)
  local _, _, a, b = string.find(line, "#([0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f])([0-3])")
  local dirs = { "R", "D", "L", "U" }
  return dirs[tonumber(b) + 1], tonumber(a, 16)
end

local function read_points(lines, read_line)
  local points = {}
  local current_pos = vector(1, 1)
  table.insert(points, current_pos)
  local n = 0

  for _, line in ipairs(lines) do
    local dir, length = read_line(line)
    current_pos = add_vecs(mult_vec(tonumber(length), direction_vec[dir]), current_pos)
    table.insert(points, current_pos)
    n = n + tonumber(length)
  end


  return points, n
end


local function run(inputfile)
  print("Running " .. inputfile)
  local lines = files.lines_from(inputfile)

  -- local map = read_map(lines)
  -- print(map)
  -- print()
  --
  -- draw_in_out(map)
  local points, n = read_points(lines, read_part1)
  print("Part 1 = " .. shoelace_area(points) + n / 2 + 1)

  points, n = read_points(lines, read_part2)
  print("Part 2 = " .. shoelace_area(points) + n / 2 + 1)
end

--------------------------------------------------------------------------
--- TESTS
--------------------------------------------------------------------------

local assert = require('test').assert

local test = {}

function test.all()
  local dir1, length1 = read_part1("R 6 (#70c710)")
  assert.equal(dir1, "R")
  assert.equal(length1, 6)

  local dir2, length2 = read_part2("R 6 (#70c710)")
  assert.equal(dir2, "R")
  assert.equal(length2, 461937)
end

-- local profile = require('profile')
-- profile.start()

test.all()
-- run("small.txt")
run("part1.txt")
-- run("input.txt")
