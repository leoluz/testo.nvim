local log = require "testo.core.log"

local M = {}

function M.display(opts, results)
  local pkg_total = 0
  local pkg_error = 0
  local pkg_success = 0
  local test_total = 0
  local test_error = 0
  local test_success = 0
  local output = {}
  for _, result in pairs(results) do
    if result.type == "package" then
      pkg_total = pkg_total + 1
      if result.status == "pass" then
        pkg_success = pkg_success + 1
      elseif result.status == "fail" then
        pkg_error = pkg_error + 1
      end
    elseif result.type == "testcase" then
      test_total = test_total + 1
      if result.status == "pass" then
        test_success = test_success + 1
      elseif result.status == "fail" then
        test_error = test_error + 1
      end
    end
    if result.output then
      for _, o in ipairs(result.output) do
        table.insert(output, o)
      end
    end
  end
  vim.schedule(
    function()
      if test_error > 0 and output then
        for _, out in ipairs(output) do
          -- This should be printed in a quickfix/floating window
          print(out)
        end
      end
      log.info(opts, "tests: total %s success %s fail %s", test_total, test_success, test_error)
    end)
end

return M
