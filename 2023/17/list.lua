local M = {}

local function deepcopy(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[deepcopy(orig_key)] = deepcopy(orig_value)
    end
    setmetatable(copy, deepcopy(getmetatable(orig)))
  else   -- number, string, boolean, etc
    copy = orig
  end
  return copy
end

---@generic T
---@param first T first element of the sequence
---@param next function<T,T> to compute the next element
---@param equal function<T,T,boolean> test equality between 2 elements
---@return integer cycle length
---@return integer starting point of the cycle
function M.cycle(first, next, equal)
  local tortoise = deepcopy(first)
  local hare = deepcopy(first)

  tortoise = next(tortoise)
  hare = next(next(hare))

  local tortoise_dist = 1
  while not equal(tortoise, hare) do
    tortoise = next(tortoise)
    hare = next(next(hare))
    tortoise_dist = tortoise_dist + 1
  end

  local start_point = 0
  tortoise = deepcopy(first)
  while not equal(tortoise, hare) do
    tortoise = next(tortoise)
    hare = next(hare)
    start_point = start_point + 1
  end

  local cycle_length = 1
  hare = next(hare)
  while not equal(tortoise, hare) do
    cycle_length = cycle_length + 1
    hare = next(hare)
  end

  return cycle_length, start_point
end

return M
