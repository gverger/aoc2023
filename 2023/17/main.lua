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

local directions = {
  { 1,  0 },
  { -1, 0 },
  { 0,  1 },
  { 0,  -1 },
}

local function distances_to_goal(map)
  local distances = grid.create(map.xmax, map.ymax, 1000000)

  local nodes = { { x = map.xmax, y = map.ymax } }

  distances:set(map.xmax, map.ymax, map:at(map.xmax, map.ymax))

  local i = 0
  while #nodes > 0 and i <= 19 do
    -- i = i + 1
    local n = table.remove(nodes, 1)
    if not n then break end

    for _, d in pairs(directions) do
      local nx = n.x + d[1]
      local ny = n.y + d[2]
      if map:contains_coords(nx, ny) then
        local heat = map:at(nx, ny) + distances:at(n.x, n.y)
        if heat < distances:at(nx, ny) then
          distances:set(nx, ny, heat)
          local next = { x = nx, y = ny }
          table.insert(nodes, next)
        end
      end
    end
  end

  return distances
end

local function next_dirs(direction)
  return tables.filter(directions, function(dir)
    return (dir[1] * direction[1] ~= -1) and (dir[2] * direction[2] ~= -1)
  end)
end


local function turn(direction)
  local next = {}
  if direction[1] == 0 then
    table.insert(next, { 1, 0 })
    table.insert(next, { -1, 0 })
  end
  if direction[2] == 0 then
    table.insert(next, { 0, 1 })
    table.insert(next, { 0, -1 })
  end
  return next
end

local function min_pos(positions)
  if #positions == 0 then return -1 end

  local min = positions[1].g + positions[1].h
  local mpos = 1
  for i, pos in pairs(positions) do
    local f = pos.g + pos.h
    if f < min then
      min = f
      mpos = i
    end
  end
  return mpos
end

local function same(node, positions)
  for _, pos in pairs(positions) do
    if pos.x == node.x and pos.y == node.y and pos.direction[1] * node.direction[1] + pos.direction[2] * node.direction[2] > 0 then
      return pos
    end
  end
  return nil
end

local function open_map(open, map)
  local om = grid.create(map.xmax, map.ymax, 0)
  for _, node in pairs(open) do
    om:set(node.x, node.y, node.g + node.h)
  end
  return om
end

local function dir_to_key(dir)
  if dir[1] > 0 then return "r" end
  if dir[1] < 0 then return "l" end
  if dir[2] > 0 then return "d" end
  if dir[2] > 0 then return "u" end
  return nil
end

local function astar(map, best_possible, min_fw, max_fw)
  local open = { { x = 1, y = 1, direction = { 0, 0 }, g = -map:at(1, 1), h = best_possible(1, 1) } }

  local close = grid.create(map.xmax, map.ymax, function() return {} end)
  local current_f = 0

  while #open > 0 do
    local node = table.remove(open, min_pos(open))
    local dk = dir_to_key(node.direction)
    if dk then
      close:at(node.x, node.y)[dk] = true
    end
    if node.x == map.xmax and node.y == map.ymax then
      return node
    end
    if node.g + node.h > current_f then
      current_f = node.g + node.h
      print(current_f)
    end

    local dirs = turn(node.direction)
    for _, dir in pairs(dirs) do
      local x = node.x
      local y = node.y
      local g = node.g
      for i = 1, max_fw do
        g = g + map:at(x, y)
        x = x + dir[1]
        y = y + dir[2]
        if not map:contains_coords(x, y) then
          break
        end
        if i < min_fw then
          goto continue
        end
        if not close:at(x, y)[dir_to_key(dir)] then
          local neighbour = {
            x = x,
            y = y,
            direction = { dir[1] * i, dir[2] * i },
            g = g,
            h = best_possible(x, y),
            parent = node,
          }
          local already_open = same(neighbour, open)
          if already_open then
            if neighbour.g < already_open.g then
              already_open.g = neighbour.g
              already_open.parent = neighbour.parent
            end
          else
            table.insert(open, neighbour)
          end
        end
        ::continue::
      end
    end
  end
  return nil
end

local function run(inputfile)
  print("Running " .. inputfile)
  local lines = files.lines_from(inputfile)

  local map = grid.read_from_lines(lines, tonumber)
  local distances = distances_to_goal(map)

  print(map)
  print(distances)

  -- local step = astar(map, function(x, y) return distances:at(x, y) end, 1, 3)
  local step = astar(map, function(x, y) return distances:at(x, y) end, 4, 10)

  local steps = {}
  while step do
    table.insert(steps, 1, step)
    step = step.parent
  end
  for _, step in ipairs(steps) do
    print(step.x .. ", " .. step.y .. " g = " .. step.g .. " h = " .. step.h .. " f = " .. step.g + step.h)
  end

  -- print("steps = " .. steps)
end

--------------------------------------------------------------------------
--- TESTS
--------------------------------------------------------------------------

local assert = require('test').assert

local test = {}

function test.direction()
  print(tables.dump(next_dirs({ 0, 1 })))
end

function test.all()
  test.direction()
end

-- test.all()
-- run("small.txt")
run("part1.txt")
-- run("input.txt")
