local config = require "gotest.core.config"
local cmd = require "gotest.core.commands"

local M = {}
M.test_nearest = cmd.test_nearest
M.setup = config.setup

return M
