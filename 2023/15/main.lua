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

---run the HASH algorithm
---@param command string
---@return integer
local function hash(command)
  local res = 0
  for i, code in ipairs(table.pack(string.byte(command, 1, #command))) do
    res = ((res + code) * 17) % 256
  end
  return res
end

---@param command string
---@return string the label
---@return string the operation - or =
---@return number? the index if operation is -
local function read(command)
  local _, _, label, operation, index = string.find(command, "([a-z]+)([=-])([0-9]*)")
  return label, operation, tonumber(index)
end

local function run(inputfile)
  print("Running " .. inputfile)
  local input = files.lines_from(inputfile)[1]
  local messages = tables.from_string(input, ",")

  print("Sum = " .. tables.sum(tables.map(messages, hash)))

  local boxes = {}
  for i = 0, 255 do
    boxes[i] = {}
  end
  for _, m in pairs(messages) do
    local label, operation, focal_length = read(m)
    local box = boxes[hash(label)]

    if operation == "=" then
      box[label] = {
        slot = (box[label] or {}).slot or tables.length(box) + 1,
        focal_length = focal_length,
      }
    elseif operation == "-" then
      if box[label] then
        for _, lens in pairs(box) do
          if lens.slot > box[label].slot then
            lens.slot = lens.slot - 1
          end
        end
      end
      box[label] = nil
    else
      error("Unknown operation " .. operation)
    end
  end

  local sum = 0
  for box_id = 0, 255 do
    local box = boxes[box_id]
    if tables.length(box) > 0 then
      print("Box " .. box_id .. ": " .. tables.dump(box))
      for _, lens in pairs(box) do
        sum = sum + (box_id + 1) * lens.slot * lens.focal_length
      end
    end
  end
  print("sum boxes = " .. sum)
end

--------------------------------------------------------------------------
--- TESTS
--------------------------------------------------------------------------

local assert = require('test').assert

local test = {}

local list = require('list')

function test.all()
  assert.equal(hash("HASH"), 52)
end

-- test.all()
-- run("part1.txt")
run("input.txt")
