local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local action_utils = require "telescope.actions.utils"
local previewers = require "telescope.previewers"
local parser = require "gotest.parser"
local go = require "gotest.go"
local M = {}

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

local function on_entry()
  local r = parser:new()
  return function(event)
    if not event then
      return
    end

    local test_event = vim.fn.json_decode(event)
    local result = r:handle_output(test_event)
    if skip_result(result) then
      return
    end

    local item = {
      value = result,
      ordinal = string.format("%s %s %s", result.status, result.name, result.elapsed),
      display = string.format("%s %s %s", r:status_icon(result.status), result.name, result.elapsed),
    }
    return item
  end
end

local function new_previewer(opts)
  return previewers.new_buffer_previewer {
    title = "Test Output",
    define_preview = function(self, entry, status)
      local lines = entry.value.output
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
    end
  }
end

local function status_icon(icon, status)
  if status then
    if status == "pause" then
      return icon.test_run
    elseif status == "cont" then
      return icon.test_run
    elseif status == "run" then
      return icon.test_run
    elseif status == "fail" then
      return icon.test_fail
    elseif status == "pass" then
      return icon.test_pass
    elseif status == "skip" then
      return icon.test_skip
    end
  end
end

local function make_entry(opts)
  return function(result)
    return {
      value = result,
      ordinal = string.format("%s %s %s", result.status, result.name, result.elapsed),
      display = string.format("%s %s %s", status_icon(opts.icon, result.status), result.name, result.elapsed),
    }
  end
end

M.display = function(opts, title, results)
  print(">>>> in display function. Results: ", vim.inspect(results))
  opts = vim.deepcopy(opts or {})
  opts.results = results
  opts.entry_maker = make_entry(opts)
  local p = pickers.new(opts, {
    prompt_title = title,
    finder = finders.new_table(opts),
    previewer = new_previewer(opts),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        print(vim.inspect(selection))
      end)
      return true
    end,
  })
  p:find()
end

M.run_nearest = function(opts)
  opts = opts or {}
  opts.entry_maker = on_entry()
  local root_dir = go.get_root_dir()
  opts.cwd = root_dir

  local test = go.find_closest_test()
  local title
  if test.name then
    title = string.format("Testing %s", test.name)
  else
    title = string.format("Testing %s", test.package)
  end
  local test_args = go.test_args(nil, test)
  local p = pickers.new(opts, {
    prompt_title = title,
    finder = finders.new_oneshot_job(
      vim.tbl_flatten {
        { "go", test_args },
      },
      opts
    ),
    previewer = new_previewer(opts),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        print(vim.inspect(selection))
      end)
      return true
    end,
  })
  p:find()
end

return M
