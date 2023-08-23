local run = require "gotest.run"
local config = require "gotest.config"

local M = {}
M.test_nearest = run.test_nearest
M.setup = config.setup

return M
