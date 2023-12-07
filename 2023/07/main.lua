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

---@class Hand
---@field cards string
---@field bid integer
local Hand = { bid = 0 }

---@return Hand
function Hand:new(o)
  return new(Hand, o)
end

function Hand:__tostring()
  return "[ cards = " .. self.cards .. ", bid = " .. self.bid .. " ]"
end

function Hand:ith_card(i)
  return string.sub(self.cards, i, i)
end

Hand.score_kind = {
  HIGH = 1,
  ONE_PAIR = 2,
  TWO_PAIRS = 3,
  THREE = 4,
  FULL = 5,
  FOUR = 6,
  FIVE = 7,
}

---@param str string
---@return table<string,integer>
local function char_counts(str)
  local counts = {}
  for c in str:gmatch "." do
    counts[c] = (counts[c] or 0) + 1
  end
  return counts
end

local NormalScorer = {}

---@param card string
function NormalScorer.card_score(card)
  for i, v in pairs({ "2", "3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K", "A" }) do
    if card == v then
      return i
    end
  end
  return 0
end

---@param hand Hand
function NormalScorer.kind(hand)
  local counts = char_counts(hand.cards)

  local max = tables.max(counts, 0)
  if max == 5 then return Hand.score_kind.FIVE end
  if max == 4 then return Hand.score_kind.FOUR end
  if max == 1 then return Hand.score_kind.HIGH end


  if max == 3 then
    if tables.min(counts, -1) == 2 then return Hand.score_kind.FULL end
    return Hand.score_kind.THREE
  end

  local nb_values = 0
  for _ in pairs(counts) do
    nb_values = nb_values + 1
  end

  if nb_values == 3 then return Hand.score_kind.TWO_PAIRS end

  return Hand.score_kind.ONE_PAIR
end

local JockerScorer = {}

---@param card string
function JockerScorer.card_score(card)
  for i, v in pairs({ "J", "2", "3", "4", "5", "6", "7", "8", "9", "T", "Q", "K", "A" }) do
    if card == v then
      return i
    end
  end
  return 0
end

---@param hand Hand
function JockerScorer.kind(hand)
  local counts = char_counts(hand.cards)

  if counts["J"] then
    local js = counts["J"]
    counts["J"] = nil

    local best_card = nil
    local max_occ = 0

    for card, occurrences in pairs(counts) do
      if card ~= "J" and occurrences > max_occ then
        max_occ = occurrences
        best_card = card
      end
    end
    if best_card then
      counts[best_card] = counts[best_card] + js
    else
      counts["J"] = js
    end
  end

  local max = tables.max(counts, 0)
  if max == 5 then return Hand.score_kind.FIVE end
  if max == 4 then return Hand.score_kind.FOUR end
  if max == 1 then return Hand.score_kind.HIGH end


  if max == 3 then
    if tables.min(counts, -1) == 2 then return Hand.score_kind.FULL end
    return Hand.score_kind.THREE
  end

  local nb_values = 0
  for _ in pairs(counts) do
    nb_values = nb_values + 1
  end

  if nb_values == 3 then return Hand.score_kind.TWO_PAIRS end

  return Hand.score_kind.ONE_PAIR
end

---comment
---@param line string
---@return Hand
local function read_hand(line)
  local cards, bid = table.unpack(tables.from_string(line, " "))
  return Hand:new {
    cards = cards,
    bid = tonumber(bid)
  }
end

---@class Problem
---@field hands Hand[]
local Problem = {}

---@return Problem
function Problem:new(o)
  o = o or {}
  o.hands = o.hands or {}
  return new(Problem, o)
end

function Problem:__tostring()
  local s = ""
  local sep = ""
  for _, h in pairs(self.hands) do
    s = s .. sep .. tostring(h)
    sep = "\n"
  end
  return s
end

---@param hands Hand[]
local function sort_hands(scorer, hands)
  table.sort(hands, function(a, b)
    local ka = scorer.kind(a)
    local kb = scorer.kind(b)
    if ka == kb then
      for i = 1, 5 do
        local sa = scorer.card_score(a:ith_card(i))
        local sb = scorer.card_score(b:ith_card(i))
        if sa ~= sb then
          return sa < sb
        end
      end
    end

    return ka < kb
  end)
  return hands
end

local function read_problem(lines)
  local p = Problem:new()
  for _, line in pairs(lines) do
    table.insert(p.hands, read_hand(line))
  end
  return p
end

local function run(filename, scorer)
  print("Running " .. filename)
  local lines = files.lines_from(filename)
  local p = read_problem(lines)

  sort_hands(scorer, p.hands)
  print(p)

  local score = 0
  for k, h in pairs(p.hands) do
    score = score + k * h.bid
  end
  print("Score = " .. score)
end

--------------------------------------------------------------------------
--- TESTS
--------------------------------------------------------------------------
local assert = require('test').assert

local test = {
  normalscorer = {},
  jockerscorer = {},
}

function test.char_counts()
  local hand = "KTJJT"
  assert.equal({ ["K"] = 1, ["T"] = 2, ["J"] = 2 }, char_counts(hand), "char_counts")
end

function test.jockerscorer.hand_kind()
  local s = Hand.score_kind
  local scorer = JockerScorer
  assert.equal(s.FOUR, scorer.kind(Hand:new { cards = "KTJJT" }), "four 2 Jockers")
  assert.equal(s.THREE, scorer.kind(Hand:new { cards = "KAJJT" }), "three 2 Jockers")
  assert.equal(s.FOUR, scorer.kind(Hand:new { cards = "JAJJT" }), "four 4 jockers")
  assert.equal(s.FIVE, scorer.kind(Hand:new { cards = "JAJJA" }), "FIVE")
  assert.equal(s.FIVE, scorer.kind(Hand:new { cards = "JJJJA" }), "FIVE")
  assert.equal(s.FIVE, scorer.kind(Hand:new { cards = "JJJJJ" }), "FIVE")
end

function test.jockerscorer.order()
  local test_cases = {
    {
      name = "threes",
      hands = { Hand:new { id = 1, cards = "T55J5" }, Hand:new { id = 2, cards = "QQQJA" } },
      order = { 1, 2 },
    },
    {
      name = "two pairs but Jocker",
      hands = { Hand:new { id = 3, cards = "KTJJT" }, Hand:new { id = 4, cards = "KK677" } },
      order = { 4, 3 },
    },
    {
      name = "pair vs two pairs",
      hands = { Hand:new { id = 5, cards = "32TK3" }, Hand:new { id = 6, cards = "KK677" } },
      order = { 5, 6 },
    },
    {
      name = "Aces",
      hands = { Hand:new { id = 7, cards = "AA2AA" }, Hand:new { id = 8, cards = "A6AAA" }, Hand:new { id = 9, cards = "AAA3A" } },
      order = { 8, 7, 9 },
    },
  }

  for _, t in pairs(test_cases) do
    sort_hands(JockerScorer, t.hands)

    assert.equal(tables.map(t.hands, function(h) return h.id end), t.order, t.name)
  end
end

function test.normalscorer.hand_kind()
  local s = Hand.score_kind
  local scorer = NormalScorer
  assert.equal(s.TWO_PAIRS, scorer.kind(Hand:new { cards = "KTJJT" }), "two pairs")
  assert.equal(s.ONE_PAIR, scorer.kind(Hand:new { cards = "KAJJT" }), "one pair")
  assert.equal(s.THREE, scorer.kind(Hand:new { cards = "JAJJT" }), "three")
  assert.equal(s.FULL, scorer.kind(Hand:new { cards = "JAJJA" }), "FULL")
  assert.equal(s.FOUR, scorer.kind(Hand:new { cards = "JJJJA" }), "four")
  assert.equal(s.FIVE, scorer.kind(Hand:new { cards = "JJJJJ" }), "five")
end

function test.normalscorer.order()
  local test_cases = {
    {
      name = "threes",
      hands = { Hand:new { id = 1, cards = "T55J5" }, Hand:new { id = 2, cards = "QQQJA" } },
      order = { 1, 2 },
    },
    {
      name = "two pairs",
      hands = { Hand:new { id = 3, cards = "KTJJT" }, Hand:new { id = 4, cards = "KK677" } },
      order = { 3, 4 },
    },
    {
      name = "pair vs two pairs",
      hands = { Hand:new { id = 5, cards = "32TK3" }, Hand:new { id = 6, cards = "KK677" } },
      order = { 5, 6 },
    },
    {
      name = "Aces",
      hands = { Hand:new { id = 7, cards = "AA2AA" }, Hand:new { id = 8, cards = "A6AAA" }, Hand:new { id = 9, cards = "AAA3A" } },
      order = { 8, 7, 9 },
    },
  }

  for _, t in pairs(test_cases) do
    sort_hands(NormalScorer, t.hands)

    assert.equal(tables.map(t.hands, function(h) return h.id end), t.order, t.name)
  end
end

function test.all()
  test.char_counts()
  test.normalscorer.hand_kind()
  test.normalscorer.order()
  test.jockerscorer.hand_kind()
  test.jockerscorer.order()
end

test.all()
-- run("part1.txt")
-- run("input.txt")
-- run("part2.txt")
-- run("part1.txt")
-- run("part1.txt", NormalScorer)
-- run("input.txt", NormalScorer)
-- run("part1.txt", JockerScorer)
run("input.txt", JockerScorer)
