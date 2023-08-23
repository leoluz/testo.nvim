local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local action_utils = require "telescope.actions.utils"
local gotest = require "go2one.gotest"

local function on_entry()
  local gt = gotest:new()
  return function(data)
    if data then
      local test_event = vim.fn.json_decode(data)
      gt:handle_output(test_event)
    end

    local prompt_bufnr = vim.api.nvim_get_current_buf()

    local new_item
    for pkg_name, pkg in pairs(gt.results) do
      local item = {
        pkg = pkg_name,
        text = string.format("%s %s %s", gt:status_icon(pkg.status), pkg_name, pkg.elapsed),
        status = pkg.status,
        output = pkg.output,
        elapsed = pkg.elapsed,
        tests = pkg.tests,
      }
      local found = false
      action_utils.map_entries(prompt_bufnr, function(entry)
        if entry.value.pkg == pkg_name then
          entry.value = item
          entry.ordinal = item.text
          entry.display = item.text
          found = true
          local current_picker = action_state.get_current_picker(prompt_bufnr)
          current_picker:refresh()
        end
      end)
      if not found then
        new_item = item
      end
    end

    if not new_item then
      return
    end

    return {
      value = new_item,
      ordinal = new_item.text,
      display = new_item.text,
    }
  end
end

local on_done = function()
  -- local prompt_bufnr = vim.api.nvim_get_current_buf()
  -- local current_picker = action_state.get_current_picker(prompt_bufnr)
  -- current_picker:refresh()
  print("done...")
end

local function get_root_dir()
  local id, client = next(vim.lsp.buf_get_clients())
  if id == nil then
    error({error_msg="lsp client not attached"})
  end
  if not client.config.root_dir then
    error({error_msg="lsp root_dir not defined"})
  end
  return client.config.root_dir
end

local run_test = function(opts)
  opts = opts or {}
  opts.entry_maker = on_entry()
  -- opts.cwd = "/Users/lalmeida1/dev/go/src/github.com/argoproj/argo-cd"
  local root_dir = get_root_dir()
  opts.cwd = root_dir
  local test_args = gotest.build_args()
  local p = pickers.new(opts, {
    prompt_title = "Running tests",
    finder_title = "Package /util/argo",
    finder = finders.new_oneshot_job(
      vim.tbl_flatten {
        test_args,
        -- "go",
        -- "test",
        -- "./util/argo/...",
        -- -- "./util/...",
        -- "-count=1",
        -- "-json",
      },
      opts
    ),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        print(vim.inspect(selection))
        -- vim.api.nvim_put({ selection[1] }, "", false, true)
      end)
      return true
    end,
  })
  p:find()

end

gotest.telescope.run_nearest()
-- run_test()
