local M = {}

---test the existence of a file
---@param file string
---@return boolean true if the file exists
function M.file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

---read lines from a text file and returns them in an array
---@param file string
---@return table<integer,string>
function M.lines_from(file)
  if not M.file_exists(file) then
    error("No such file: " .. file)
  end

  local lines = {}
  for line in io.lines(file) do
    lines[#lines + 1] = line
  end
  return lines
end

return M
