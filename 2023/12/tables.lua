local M = {}

function M.is_array(tbl)
  return tbl[1] ~= nil
end

---serialize a value
---@param o any
---@return string
function M.dump(o)
  if type(o) ~= "table" or o.__tostring then
    return tostring(o)
  end

  if M.is_array(o) then
    if #o == 0 then
      return '[]'
    end
    local s = '[ '
    local sep = ""
    for _, v in pairs(o) do
      s = s .. sep .. M.dump(v)
      sep = ', '
    end
    return s .. ']'
  end

  local s = '{ '
  local sep = ""
  for k, v in pairs(o) do
    if type(k) ~= 'number' then k = '"' .. k .. '"' end
    s = s .. sep .. '[' .. k .. '] = ' .. M.dump(v)
    sep = ', '
  end
  return s .. '}'
end

---map each element of the table thanks to the given function
---@generic T
---@generic U
---@param tbl T[]
---@param f function<T,U>
---@return U[]
function M.map(tbl, f)
  local t = {}
  for k, v in pairs(tbl) do
    t[k] = f(v, k)
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

local function first_value(tbl)
  for _, value in pairs(tbl) do
    return value
  end
  return nil
end

---get the minimal value in the table, or a default value when the table is empty
---@param tbl table<any, number>
---@param default number
---@return number
function M.min(tbl, default)
  local m = first_value(tbl) or default

  for _, v in pairs(tbl) do
    if m > v then
      m = v
    end
  end
  return m
end

---get the maximal value in the table, or a default value when the table is empty
---@param tbl number[]
---@param default number
---@return number
function M.max(tbl, default)
  local m = first_value(tbl) or default

  for _, v in pairs(tbl) do
    if m < v then
      m = v
    end
  end
  return m
end

function M.length(tbl)
  local count = 0
  for _ in pairs(tbl) do
    count = count + 1
  end
  return count
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

---filter a table to only keep the filtered elements
---@generic T
---@param tbl T[]
---@return T[]
function M.reverse(tbl)
  local rev = {}
  for i = #tbl, 1, -1 do
    table.insert(rev, tbl[i])
  end
  return rev
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

---return true if any element satisfies the solution
---@param tbl table
---@param filter function
---@return boolean
function M.all(tbl, filter)
  for _, value in pairs(tbl) do
    if not filter(value) then
      return false
    end
  end
  return true
end

function M.chars_of(inputstr)
  local t = {}
  for str in string.gmatch(inputstr, ".") do
    table.insert(t, str)
  end
  return t
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

---creates a map which is a lookup for the table
---@generic T
---@generic U
---@param tbl table<any, T>
---@param index function<T, U>
---@return table<U, T>
function M.lookup(tbl, index)
  local lookup = {}
  for _, el in pairs(tbl) do
    lookup[index(el)] = el
  end

  return lookup
end

function M.join(tbl, sep)
  if sep == nil then
    sep = ", "
  end
  local separator = ""

  local s = ""
  for _, value in pairs(tbl) do
    s = s .. separator .. tostring(value)
    separator = sep
  end

  return s .. ""
end

---@param tbl string[]
---@param sep string
---@return string[][]
function M.split(tbl, sep)
  if sep == nil then
    sep = ""
  end

  local t = {}
  local current = nil
  for _, el in pairs(tbl) do
    if el == sep then
      current = nil
      goto continue
    end

    if current == nil then
      current = {}
      table.insert(t, current)
    end
    table.insert(current, el)

    ::continue::
  end
  return t
end

return M
