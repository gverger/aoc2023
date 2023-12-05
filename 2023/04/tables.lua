local M = {}

local function is_array(tbl)
  return not M.any(tbl, function(e)
    return e == nil
  end)
end

---serialize a value
---@param o any
---@return string
function M.dump(o)
  if type(o) ~= "table" then
    return tostring(o)
  end

  if is_array(o) then
    if #o == 0 then
      return '[]'
    end
    local s = '[ '
    for _, v in pairs(o) do
      s = s .. M.dump(v) .. ','
    end
    return s .. ']'
  end

  local s = '{ '
  for k, v in pairs(o) do
    if type(k) ~= 'number' then k = '"' .. k .. '"' end
    s = s .. '[' .. k .. '] = ' .. M.dump(v) .. ','
  end
  return s .. '}'
end

---map each element of the table thanks to the given function
---@generic T
---@generic U
---@param tbl table<integer,T>
---@param f function<T,U>
---@return table<integer, U>
function M.map(tbl, f)
  local t = {}
  for k, v in pairs(tbl) do
    t[k] = f(v)
  end
  return t
end

---sum all table elements
---@param tbl table<integer, number>
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

---get the maximal value in the table, or a default value when the table is empty
---@param tbl table<integer, number>
---@param default number
---@return number
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

---count the number of filtered elements in the table
---@generic T
---@param tbl table<integer, T>
---@param filter function<T,boolean>
---@return integer
function M.count(tbl, filter)
  local count = 0
  for _, value in pairs(tbl) do
    if filter(value) then
      count = count + 1
    end
  end
  return count
end

---filter a table to only keep the filtered elements
---@generic T
---@param tbl table<integer, T>
---@param filter function<T, boolean>
---@return table
function M.filter(tbl, filter)
  local filtered = {}
  for _, value in pairs(tbl) do
    if filter(value) then
      table.insert(filtered, value)
    end
  end
  return filtered
end

---return true if any element satisfies the solution
---@param tbl table
---@param filter function
---@return boolean
function M.any(tbl, filter)
  for _, value in pairs(tbl) do
    if filter(value) then
      return true
    end
  end
  return false
end

---split a string and put elements in a table
---@param inputstr string
---@param sep string the separator, a character, (space by default)
---@return table<integer, string>
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
