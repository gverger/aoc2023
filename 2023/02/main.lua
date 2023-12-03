local tables = require('tables')

local files = require('files')

Reveal = {}
function Reveal:new(line)
  local r = {}
  setmetatable(r, self)
  self.__index = self

  r.blue = tonumber(string.match(line, "(%d+) blue")) or 0
  r.red = tonumber(string.match(line, "(%d+) red")) or 0
  r.green = tonumber(string.match(line, "(%d+) green")) or 0

  return r
end

function Reveal:__tostring()
  return "(r: " .. self.red .. ", g: " .. self.green .. ", b: " .. self.blue .. ")"
end

Game = {}
function Game:new(line)
  local g = {}
  setmetatable(g, self)
  self.__index = self

  local header, game = table.unpack(tables.from_string(line, ":"))
  g.id = tonumber(string.match(header, "Game (%d+)"))

  g.reveals = {}
  local reveals = tables.from_string(game, ";")
  for _, x in pairs(reveals) do
    table.insert(g.reveals, Reveal:new(x))
  end

  return g
end

function Game:__tostring()
  local str = "Game: " .. self.id .. " "
  for _, reveal in pairs(self.reveals) do
    str = str .. reveal:__tostring()
  end
  return str
end

function Game:max()
  return {
    blue = tables.max(tables.map(self.reveals, function(r) return r.blue end), 0),
    red = tables.max(tables.map(self.reveals, function(r) return r.red end), 0),
    green = tables.max(tables.map(self.reveals, function(r) return r.green end), 0),
  }
end

function Game:power()
  local m = self:max()
  return m.blue * m.red * m.green
end

local function possible_games(games, red, green, blue)
  return tables.filter(games,
    function(game)
      local max = game:max()
      return max.blue <= blue and max.red <= red and max.green <= green
    end)
end

local function main(input_file)
  print("Input = " .. input_file)

  local all_games = tables.map(
    files.lines_from(input_file),
    function(line) return Game:new(line) end
  )

  local ok_games = possible_games(all_games, 12, 13, 14)
  local sum_of_possibles = tables.sum(
    tables.map(
      ok_games,
      function(game) return game.id end
    ))
  print("Sum = " .. sum_of_possibles)

  local power = tables.sum(tables.map(all_games, Game.power))
  print("Power = " .. power)
end

main("part1.txt")
main("part2.txt")
main("input.txt")
