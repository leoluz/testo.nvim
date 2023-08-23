local run = require "go2one.gotest.run"
local config = require "go2one.gotest.config"

local M = {}
M.test_nearest = run.test_nearest
M.setup = config.setup

return M
