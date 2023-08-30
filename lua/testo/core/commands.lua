local config = require "testo.core.config"
local runner = require "testo.runner.gotest"
local locate = require "testo.locator.gotest"

local M = {}

function M.test_nearest(opts)
  local cfg = vim.tbl_deep_extend("force", config.get(), opts or {})

  local test = locate.closest_test()
  local r = runner:new(cfg, test)
  r:run(test, opts)
end

return M
