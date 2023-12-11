local M = {}

M.LEVELS = {
  NONE = { value = 0 },
  ERROR = { value = 1, prefix = "ERROR  : " },
  WARNING = { value = 2, prefix = "WARNING: " },
  INFO = { value = 3, prefix = "INFO   : " },
  DEBUG = { value = 4, prefix = "DEBUG  : " },
}

M.LEVEL = M.LEVELS.INFO

local function log(level, message)
  if level.value <= M.LEVEL.value then
    print(level.prefix .. message)
  end
end

---@param message string
function M.info(message)
  log(M.LEVELS.INFO, message)
end

function M.debug(message)
  log(M.LEVELS.DEBUG, message)
end

return M
