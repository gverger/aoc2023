local M = {}

local assert = {}
M.assert = assert

local function err(identifier)
  return function(message) error(string.format("%s: %s", identifier, message)) end
end

function assert.equal(a, b, identifier)
  if not identifier then
    identifier = ""
  end
  local error = err(identifier)

  local ta = type(a)
  local tb = type(b)
  if ta ~= tb then
    error(string.format("different types %s and %s", ta, tb))
  end

  if ta == "table" then
    local done = {}
    for key, value in pairs(a) do
      assert.equal(value, b[key], identifier .. ": " .. "field ." .. key)
      done[key] = true
    end
    for key, value in pairs(b) do
      if not done[key] then
        assert.equal(a[key], value, identifier .. ": " .. "field ." .. key)
      end
    end
  else
    if a ~= b then
      error("not equal: " .. a .. " and " .. b)
    end
  end
end

return M
