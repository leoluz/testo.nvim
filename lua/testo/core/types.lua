---@enum STATUS
local Status = {
  pause = "pause",
  cont = "cont",
  run = "run",
  fail = "fail",
  pass = "pass",
  skip = "skip",
}

---@class ExecutionResult represents the result of a test execution.
---@field [string] PackageResult The key is the package name

---@class PackageResult
---@field status STATUS
---@field elapsed string
---@field output string
---@field tests Tests

---@class Tests
---@field [string] TestResult The key is the test name

---@class TestResult
---@field status STATUS
---@field elapsed string
---@field output string
---@field file string
---@field line string

---@class Options
---@field icon_test_fail string
---@field icon_test_run string
---@field icon_test_pass string
---@field icon_test_skip string
