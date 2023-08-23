local M = {}

local config = {
  results_handler = "notification",
  icon = {
    test_fail = '🔴',
    test_run  = '🟡',
    test_pass = '🟢',
    test_skip = '🔵',
  }
}

M.setup = function(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})
end

M.get = function()
  return config
end

return M
