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

---@enum Pulse
local Pulse = {
  low = 0,
  high = 1,
}


---@class CommunicationModule
---@field name string
---@field outs CommunicationModule[]
---@field out_names string[]
---@field low_pulses_sent integer
---@field high_pulses_sent integer
local CommunicationModule = {}

---@return CommunicationModule
function CommunicationModule:new(o)
  local cm = new(self, o)
  cm.low_pulses_sent = cm.low_pulses_sent or 0
  cm.high_pulses_sent = cm.high_pulses_sent or 0
  cm.name = cm.name or ""
  cm.outs = cm.outs or {}
  cm.out_names = cm.out_names or {}
  return cm
end

local Well = CommunicationModule:new()

---@return Well
function Well:new(o)
  return new(self, o)
end

function Well:handle_pulse(pulse, from)
end

---@param p Problem
function CommunicationModule:connect(p)
  self.outs = tables.map(self.out_names, function(name)
    p.modules[name] = p.modules[name] or Well:new { name = name }
    return p.modules[name]
  end)
end

---@param pulse Pulse
---@param from string
function CommunicationModule:receive_pulse(pulse, from)
end

---@param pulse Pulse
---@param from string
function CommunicationModule:handle_pulse(pulse, from)
  error("handle_pulse not implemented")
end

---@param pulse Pulse
function CommunicationModule:send_pulse(pulse)
  for _, m in pairs(self.outs) do
    log.debug(self.name .. "-" .. pulse .. "-> " .. m.name)
    if pulse == Pulse.high then
      self.high_pulses_sent = self.high_pulses_sent + 1
    else
      self.low_pulses_sent = self.low_pulses_sent + 1
    end
    m:receive_pulse(pulse, self.name)
  end

  for _, m in pairs(self.outs) do
    m:handle_pulse(pulse, self.name)
  end
end

---@enum Status
local Status = {
  off = 0,
  on = 1,
}

---@param status Status
function Status.flip(status)
  return 1 - status
end

---@class FlipFlop: CommunicationModule
---@field status Status
local FlipFlop = CommunicationModule:new()

---@return FlipFlop
function FlipFlop:new(o)
  local f = new(self, o)
  f.status = f.status or Status.off
  return f
end

---@param pulse Pulse
function FlipFlop:handle_pulse(pulse, _)
  if pulse == Pulse.low then
    self.status = Status.flip(self.status)
    if self.status == Status.on then
      self:send_pulse(Pulse.high)
    else
      self:send_pulse(Pulse.low)
    end
  end
end

---@class Conjunction: CommunicationModule
---@field ins {[string]: Pulse}
local Conjunction = CommunicationModule:new()

---@return Conjunction
function Conjunction:new(o)
  local c = new(self, o)
  c.ins = c.ins or {}
  return c
end

---@param module_name string
function Conjunction:add_input(module_name)
  self.ins[module_name] = Pulse.low
end

---@param pulse Pulse
---@param from string
function Conjunction:receive_pulse(pulse, from)
  if not self.ins[from] then
    error(from .. " is not listed as an input of " .. self.name)
  end
  self.ins[from] = pulse
end

---@param pulse Pulse
---@param from string
function Conjunction:handle_pulse(pulse, from)
  if tables.all(self.ins, function(last_in) return last_in == Pulse.high end) then
    self:send_pulse(Pulse.low)
  else
    self:send_pulse(Pulse.high)
  end
end

function Conjunction:connect(p)
  CommunicationModule.connect(self, p)
  for _, m in pairs(p.modules) do
    if tables.any(m.out_names, function(name) return name == self.name end) then
      self.ins[m.name] = Pulse.low
    end
  end
end

---@class Broadcast: CommunicationModule
local Broadcast = CommunicationModule:new()

---@return Broadcast
function Broadcast:new(o)
  return new(self, o)
end

function Broadcast:handle_pulse(pulse, _)
  self:send_pulse(pulse)
end

---@class Problem
---@field modules { [string]: CommunicationModule }
local Problem = {}

---@return Problem
function Problem:new(o)
  local p   = new(self, o)
  p.modules = p.modules or {}
  return p
end

function Problem:wire_modules()
  for _, m in pairs(self.modules) do
    m:connect(self)
  end
end

---reads a module line
---@param line string
---@return CommunicationModule
local function read_module(line)
  local _, _, prefix, name, outputs = string.find(line, "([%%&]?)([a-z]+) %-> (.+)")
  local out_names = tables.from_string(outputs, ", ")
  if name == "broadcaster" then
    return Broadcast:new { name = name, out_names = out_names }
  elseif prefix == "%" then
    return FlipFlop:new { name = name, out_names = out_names }
  elseif prefix == "&" then
    return Conjunction:new { name = name, out_names = out_names }
  end
  error("unrecognized module '" .. line "'")
end

---@param lines string[]
---@return Problem
local function read_problem(lines)
  local p = Problem:new()
  for _, line in pairs(lines) do
    local m = read_module(line)
    p.modules[m.name] = m
  end

  local button = Broadcast:new { name = "button", out_names = { "broadcaster" } }
  p.modules["button"] = button

  p:wire_modules()

  return p
end


local function run(inputfile)
  print("Running " .. inputfile)
  local lines = files.lines_from(inputfile)

  local p = read_problem(lines)

  for _ = 1, 1000 do
    p.modules["button"]:handle_pulse(Pulse.low, "start")
  end

  local low_pulses_sent = tables.sum(tables.map(p.modules, function(m) return m.low_pulses_sent end))
  local high_pulses_sent = tables.sum(tables.map(p.modules, function(m) return m.high_pulses_sent end))

  print("Pulses sent low = " ..
    low_pulses_sent .. " high = " .. high_pulses_sent .. " = " .. low_pulses_sent * high_pulses_sent)
end

--------------------------------------------------------------------------
--- TESTS
--------------------------------------------------------------------------

local assert = require('test').assert

local test = {}

---@class TestPulse: CommunicationModule
local TestPulse = CommunicationModule:new()

---@return TestPulse
function TestPulse:new(o)
  return new(self, o)
end

---@param first CommunicationModule
---@param m CommunicationModule? will be same as first if nil
---@return fun(pulse: Pulse, from?: string), Pulse[]
local function experiment(first, m)
  m = m or first

  local result = {}
  local tp = TestPulse:new {
    handle_pulse = function(_, pulse, _)
      table.insert(result, pulse)
    end
  }

  table.insert(m.outs, tp)

  local send = function(pulse, from)
    from = from or "start"
    tables.clear(result)
    first:receive_pulse(pulse, from)
    first:handle_pulse(pulse, from)
  end

  return send, result
end

function test.flip_flop()
  local m = FlipFlop:new()
  local send, result = experiment(m)
  for _ = 1, 5 do
    send(Pulse.high)
    assert.equal(result, {}, "no activation with high pulses")
  end

  send(Pulse.low)
  assert.equal(result, { Pulse.high }, "from off to on -> high pulse")

  for _ = 1, 5 do
    send(Pulse.high)
    assert.equal(result, {}, "no activation with high pulses")
  end

  send(Pulse.low)
  assert.equal(result, { Pulse.low }, "from on to off -> high pulse")

  for _ = 1, 5 do
    send(Pulse.high)
    assert.equal(result, {}, "no activation with high pulses")
  end
end

function test.conjunction()
  local m = Conjunction:new { ins = { in1 = Pulse.low, in2 = Pulse.low, in3 = Pulse.high } }
  local send, result = experiment(m)

  send(Pulse.high, "in1")
  assert.equal(result, { Pulse.high }, "2 inputs are high")

  send(Pulse.high, "in2")
  assert.equal(result, { Pulse.low }, "3 inputs are high")

  send(Pulse.high, "in2")
  assert.equal(result, { Pulse.low }, "3 inputs are high")
end

function test.read_broadcaster()
  local line = "broadcaster -> a, b, c"
  assert.equal(read_module(line), Broadcast:new { name = "broadcaster", outs = {}, out_names = { "a", "b", "c" } },
    "reading broadcaster")
end

function test.read_flipflop()
  local line = "%cd -> jx, gh"
  local m = read_module(line)
  local expected = FlipFlop:new { name = "cd", out_names = { "jx", "gh" } }
  assert.equal(m, expected, "reading flipflop " .. tables.dump(read_module(line)))
end

function test.read_conjunction()
  local line = "&cn -> sh, jd, cx, tc, xd"
  local m = read_module(line)
  assert.equal(m,
    Conjunction:new { name = "cn", out_names = { "sh", "jd", "cx", "tc", "xd" } },
    "reading conjunction " .. tables.dump(read_module(line)))
end

function test.all()
  print("Running test")
  for name, fun in pairs(test) do
    if name ~= "all" and type(fun) == "function" then
      print("- test " .. name)
      fun()
    end
  end
  print("...Done")
end

test.all()
-- run("part1.txt")
-- run("part2.txt")
run("input.txt")
