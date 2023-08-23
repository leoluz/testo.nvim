local job = require "plenary.job"
local go = require "go2one.gotest.go"
local log = require "go2one.gotest.log"
local parser = require "go2one.gotest.parser"
local config = require "go2one.gotest.config"
local M = {}
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

local function notify(opts, results)
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
            notify(opts, self.results)
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

function M.test_nearest(opts)
    local cfg = vim.tbl_deep_extend("force", config.get(), opts or {})

    local root_dir = go.get_root_dir()
    cfg.cwd = root_dir

    local test = go.find_closest_test()
    local test_args = go.test_args(nil, test)
    local r = runner:new(cfg, test)
    local j = job:new({
        command = 'go',
        args = test_args,
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

return M
