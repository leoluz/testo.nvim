local job = require "plenary.job"
local log = require "gotest.core.log"
local parser = require "gotest.parser.gotest"
local config = require "gotest.core.config"
local minimalist = require "gotest.view.minimalist"
local runner = {}
runner.__index = runner

function runner:new(opts, test)
  local obj = {
    opts = vim.deepcopy(opts),
    test = test,
    parser = parser:new(),
    results = {},
  }
  setmetatable(obj, self)
  return obj
end

function runner:on_start()
  return function()
    log.info(self.opts, "Running %s", self:test_name())
  end
end

function runner:test_name()
  if self.test.name then
    return self.test.name
  end
  return self.test.package
end

local function skip_result(result)
  if result.status ~= "fail" and
      result.status ~= "pass" or
      result.type == "package" then
    return true
  end
  if result.status == "fail" and
      not next(result.output) then
    return true
  end
  return false
end

function runner:on_stdout()
  return function(err, data)
    if err then
      local msg = "error running test %s runner:on_stdout: %s"
      log.error(self.opts, msg, self:test_name(), err)
    end
    if not data then
      return
    end
    vim.schedule(
      function()
        local test_event = vim.fn.json_decode(data)
        local result = self.parser:handle_output(test_event)
        if not skip_result(result) then
          table.insert(self.results, result)
        end
      end)
  end
end

function runner:on_stderr()
  return function(err, data)
    if err ~= nil then
      data = data or {}
      local msg = "error running test %s runner:on_stderr: err: %s data: %s"
      log.error(self.opts, msg, self:test_name(), err, data)
    end
  end
end

function runner:on_exit(opts)
  return function(_, _, signal)
    if signal ~= 0 then
      vim.schedule(
        function()
          log.error(opts, "test execution error: signal received: %s)", signal)
        end)
      return
    end
    local handler = opts.results_handler
    if handler == "notification" then
      minimalist.display(opts, self.results)
    elseif handler == "telescope" then
      local telescope = require 'go2one.gotest.telescope'
      vim.schedule(
        function()
          telescope.display(opts, self:test_name(), self.results)
        end)
    else
      vim.schedule(
        function()
          log.error(opts, "gotest configuration error: config.results_handler %s: not recognized",
            opts.results_handler)
        end)
      return
    end
  end
end

local function get_root_dir()
  local id, client = next(vim.lsp.buf_get_clients())
  if id == nil then
    error({ error_msg = "lsp client not attached" })
  end
  if not client.config.root_dir then
    error({ error_msg = "lsp root_dir not defined" })
  end
  return client.config.root_dir
end


local function test_args(pkg, test)
  local args = { "test" }
  if pkg then
    table.insert(args, pkg)
  else
    table.insert(args, test.package)
    if test.scope == "testcase" then
      table.insert(args, "-test.run")
      table.insert(args, "^" .. test.name .. "$")
    end
  end
  table.insert(args, "-count=1")
  table.insert(args, "-json")
  return args
end


function runner:run(test, opts)
  local cfg = vim.tbl_deep_extend("force", config.get(), opts or {})

  local root_dir = get_root_dir()
  cfg.cwd = root_dir

  local args = test_args(nil, test)
  local r = runner:new(cfg, test)
  local j = job:new({
    command = 'go',
    args = args,
    cwd = cfg.cwd,
    on_start = r:on_start(),
    on_stdout = r:on_stdout(),
    on_stderr = r:on_stderr(),
    on_exit = r:on_exit(cfg),
  })
  j:start()
  return {
    root_dir = root_dir,
    test_case = test.name,
    test_pkg = test.package,
  }
end

return runner
