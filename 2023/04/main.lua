local tables = require('tables')

local files = require('files')

local function numbers_in(line)
  local numbers = {}
  for n in string.gmatch(line, "(%d+)") do
    table.insert(numbers, n)
  end
  return numbers
end

---@class Card
---@field id integer
---@field goal integer[]
---@field gotten integer[]
Card = {}
function Card:new(line)
  local c = {}
  setmetatable(c, self)
  self.__index = self

  local id, goal, gotten = string.match(line, "Card%s+(%d+): (.*) | (.*)")

  c.id = tonumber(id)
  c.goal = numbers_in(goal)
  c.gotten = numbers_in(gotten)

  return c
end

---Get the number of numbers found
---@return integer
function Card:nb_found()
  local expected = {}
  for _, n in pairs(self.goal) do
    expected[n] = true
  end

  return tables.count(self.gotten, function(n)
    return expected[n]
  end)
end

---returns the number of points for n numbers found
---@param n integer
---@return integer
local function points_for_n_found(n)
  if n == 0 then
    return 0
  end
  return (1 << (n - 1))
end

local function main(input_file)
  print("Input = " .. input_file)

  local lines = files.lines_from(input_file)
  local points = 0
  for _, line in pairs(lines) do
    local found = Card:new(line):nb_found()
    local card_points = points_for_n_found(found)
    points = points + card_points
    print(line .. " => " .. found .. " found = " .. card_points)
  end

  print("Points = " .. points)

  local found_per_card = {}
  for _, line in pairs(lines) do
    local found = Card:new(line):nb_found()
    table.insert(found_per_card, found)
  end

  print(tables.dump(found_per_card))

  local gained = {}
  for i = 1, #found_per_card do
    gained[i] = 1
  end
  for i, found in pairs(found_per_card) do
    for j = i + 1, i + found do
      local current = gained[j]
      gained[j] = current + gained[i]
    end
  end

  print("Points = " .. tables.sum(gained) .. " " .. tables.dump(gained))
end

main("part1.txt")
