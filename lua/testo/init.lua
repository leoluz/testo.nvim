local config = require "testo.core.config"
local cmd = require "testo.core.commands"

local M = {}
M.test_nearest = cmd.test_nearest
M.setup = config.setup

return M
