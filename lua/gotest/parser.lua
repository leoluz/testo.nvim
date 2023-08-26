---@class Gotest
---@field opts Options
---@field results ExecutionResult
local gotest = {}
gotest.__index = gotest

---@param opts Options
---@return Options
local function handle_opts(opts)
  local options = {
    icon_test_fail = '🔴',
    icon_test_run  = '🟡',
    icon_test_pass = '🟢',
    icon_test_skip = '🔵'
  }
  if opts then
    for k, v in pairs(opts) do
      options[k] = v
    end
  end
  return options
end

---@param opts? Options
---@return Gotest
function gotest:new(opts)
  local options = handle_opts(vim.deepcopy(opts))
  local o = {
    opts = options,
    results = {}
  }
  setmetatable(o, self)
  return o
end

---Return the unicode character representing the icon for the given status.
---Will return empty string if is not defined.
---@param status STATUS
---@return string
function gotest:status_icon(status)
  if status then
    if status == "pause" then
      return self.opts.icon_test_run
    elseif status == "cont" then
      return self.opts.icon_test_run
    elseif status == "run" then
      return self.opts.icon_test_run
    elseif status == "fail" then
      return self.opts.icon_test_fail
    elseif status == "pass" then
      return self.opts.icon_test_pass
    elseif status == "skip" then
      return self.opts.icon_test_skip
    end
  end
  return ""
end

---Will try to extract the file and the line from the given output
---@param output string
---@return string # the filename
---@return string # the line number
---@return string # the output
function gotest:clean_output(output)
  if not string.find(output, "%s*===.+") and not string.find(output, "%s*%-%-%-.+") then
    local file, line = string.match(output, "%s*(.+):(%d+):%s.+")
    return file, line, output
  end
end

function gotest:handle_output(test_event)
  assert(test_event)
  if not test_event.Package then
    return
  end
  local pkg = test_event.Package
  if self.results[pkg] == nil then
    self.results[pkg] = {
      status = '',
      elapsed = '',
      output = {},
      tests = {}
    }
  end
  if test_event.Elapsed and not test_event.Test then
    self.results[pkg].elapsed = test_event.Elapsed
  end
  if test_event.Action ~= 'output' and
      test_event.Action ~= 'bench' and
      self.results[pkg].status ~= 'fail' then
    self.results[pkg].status = test_event.Action
  end
  local test
  if test_event.Test then
    test = test_event.Test
    if self.results[pkg].tests[test] == nil then
      self.results[pkg].tests[test] = {
        status = '',
        elapsed = '',
        output = {}
      }
    end
    if test_event.Action ~= 'output' then
      self.results[pkg].tests[test].status = test_event.Action
      if test_event.Elapsed then
        self.results[pkg].tests[test].elapsed = test_event.Elapsed
      end
    else
      local file, line_nr, output = self:clean_output(test_event.Output)
      if file then
        self.results[pkg].tests[test].file = file
      end
      if line_nr then
        self.results[pkg].tests[test].line = line_nr
      end

      if output then
        local lines = vim.split(output, "\n")
        for _, line in ipairs(lines) do
          if line ~= "" then
            table.insert(self.results[pkg].tests[test].output, line)
          end
        end
      end
    end
  else
    if test_event.Action == 'output' then
      local out = test_event.Output
      local lines = vim.split(out, "\n")
      for _, line in ipairs(lines) do
        if line ~= "" then
          table.insert(self.results[pkg].output, line)
        end
      end
    end
  end


  local result = {}
  if test then
    result = {
      type = "testcase",
      name = string.format("%s/%s", pkg, test),
      status = self.results[pkg].tests[test].status,
      elapsed = self.results[pkg].tests[test].elapsed,
      output = self.results[pkg].tests[test].output,
      file = self.results[pkg].tests[test].file,
      line = self.results[pkg].tests[test].line,
    }
  else
    result = {
      type = "package",
      name = pkg,
      status = self.results[pkg].status,
      elapsed = self.results[pkg].elapsed,
      output = self.results[pkg].output,
    }
  end
  return result
end

return gotest
