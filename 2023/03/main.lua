local tables = require('tables')

local files = require('files')

local function numbers_in(line)
  local numbers = {}
  local idx = 1
  while idx <= #line do
    local i, j, n = string.find(line, "(%d+)", idx)
    if n == nil then
      break
    end
    local number = { from = tonumber(i), to = tonumber(j), n = tonumber(n) }
    table.insert(numbers, number)
    idx = j + 1
  end

  return numbers
end

local function symbols_in(line)
  local symbols = {}
  local idx = 1
  while idx <= #line do
    local i, j, s = string.find(line, "([^%d.])", idx)
    if s == nil then
      break
    end
    local number = { from = tonumber(i), to = tonumber(j), s = s }
    table.insert(symbols, number)
    idx = j + 1
  end

  return symbols
end

Row = {}
function Row:new(line)
  local r = {}
  setmetatable(r, self)
  self.__index = self

  r.numbers = numbers_in(line)
  r.symbols = symbols_in(line)

  return r
end

function Row.default()
  return Row:new("")
end

Grid = {}
function Grid:new(lines)
  local g = {}
  setmetatable(g, self)
  self.__index = self

  g.rows = {}
  for _, l in pairs(lines) do
    table.insert(g.rows, Row:new(l))
  end
  return g
end

function Grid:row(i)
  if i < 1 or i > #self.rows then
    return Row.default()
  end

  return self.rows[i]
end

function Grid:numbers_touching_symbols()
  local numbers = {}
  for i, r in pairs(self.rows) do
    local symbols = {}
    local rows = {
      self:row(i),
      self:row(i - 1),
      self:row(i + 1),
    }

    for _, row in pairs(rows) do
      for _, s in pairs(row.symbols) do
        symbols[s.from] = true
      end
    end

    local function is_touched(n)
      for ig = n.from - 1, n.to + 1, 1 do
        if symbols[ig] then
          return true
        end
      end
      return false
    end

    for _, n in pairs(r.numbers) do
      if is_touched(n) then
        table.insert(numbers, n.n)
      end
    end
  end
  return numbers
end

function Grid:gears()
  local sum = 0
  for i, r in pairs(self.rows) do
    for _, symbol in pairs(r.symbols) do
      if symbol.s == "*" then
        local numbers = {}

        local rows = { self:row(i), self:row(i - 1), self:row(i + 1) }

        for _, row in pairs(rows) do
          local touched_numbers = tables.filter(row.numbers, function(n)
            return n.from - 1 <= symbol.from and symbol.to <= n.to + 1
          end)
          for _, n in pairs(touched_numbers) do
            table.insert(numbers, n)
          end
        end

        if #numbers == 2 then
          sum = sum + numbers[1].n * numbers[2].n
        end
      end
    end
  end
  return sum
end

local function main(input_file)
  print("Input = " .. input_file)

  local lines = files.lines_from(input_file)
  for _, line in pairs(lines) do
    print(line)
  end

  local grid = Grid:new(lines)

  print(tables.sum(grid:numbers_touching_symbols()))
  print(grid:gears())
end

main("part1.txt")
-- main("part2.txt")
main("input.txt")
