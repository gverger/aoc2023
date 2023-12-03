local M = {}

function M.dump(o)
  if type(o) == 'table' then
    local s = '{ '
    for k, v in pairs(o) do
      if type(k) ~= 'number' then k = '"' .. k .. '"' end
      s = s .. '[' .. k .. '] = ' .. M.dump(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end

-- @param tbl table
-- @param f function
function M.map(tbl, f)
  local t = {}
  for k, v in pairs(tbl) do
    t[k] = f(v)
  end
  return t
end

function M.sum(tbl)
  if #tbl == 0 then
    return 0
  end

  local s = 0
  for _, v in pairs(tbl) do
    s = s + v
  end
  return s
end

function M.max(tbl, default)
  if #tbl == 0 then
    return default
  end

  local m = tbl[1]
  for _, v in pairs(tbl) do
    if m < v then
      m = v
    end
  end
  return m
end

function M.filter(tbl, filter)
  local filtered = {}
  for _, value in pairs(tbl) do
    if filter(value) then
      table.insert(filtered, value)
    end
  end
  return filtered
end

function M.from_string(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end

  local t = {}
  for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
    table.insert(t, str)
  end
  return t
end

return M
