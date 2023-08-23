local M = {}

local function notify(opts, level, msg, ...)
  local message
  if ... then
    message = string.format(msg, unpack({...}))
  else
    message = msg
  end
  vim.schedule(function()
    vim.notify(message, level, opts)
  end)
end

M.info = function(opts, msg, ...)
  notify(opts, vim.log.levels.INFO, msg, ...)
end

M.warn = function(opts, msg, ...)
  notify(opts, vim.log.levels.WARN, msg, ...)
end

M.error = function(opts, msg, ...)
  notify(opts, vim.log.levels.ERROR, msg, ...)
end

M.degub = function(opts, msg, ...)
  notify(opts, vim.log.levels.DEBUG, msg, ...)
end

return M
