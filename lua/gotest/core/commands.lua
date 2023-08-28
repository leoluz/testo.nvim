local config = require "gotest.core.config"
local runner = require "gotest.runner.gotest"
local find = require "gotest.core.finder"

local M = {}

function M.test_nearest(opts)
  local cfg = vim.tbl_deep_extend("force", config.get(), opts or {})

  local test = find.closest_test()
  local r = runner:new(cfg, test)
  r:run(test, opts)
end

return M
