local actions = require "telescope.actions"
local finders = require "telescope.finders"
local pickers = require "telescope.pickers"
local utils = require "telescope.utils"
local popup = require "plenary.popup"
local conf = require("telescope.config").values
local make_entry = require "telescope.make_entry"

local gh_pr_a = require "telescope._extensions.gh_pr_actions"
local gh_pr_p = require "telescope._extensions.gh_pr_previewers"

local B = {}

local function parse_gh_pr_opts(opts)
  local query = {}
  local tmp_table = {
    "assignee",
    "label",
    "search",
    "state",
    "base",
    "limit",
  }

  for _, value in pairs(tmp_table) do
    if opts[value] then
      table.insert(query, {
        "--" .. value,
        opts[value],
      })
    end
  end

  return query
end

local function load_with_prompt(message, command, callback)
  local line = math.floor((vim.o.lines - 5) / 2)
  local width = math.floor(vim.o.columns / 1.5)
  local col = math.floor((vim.o.columns - width) / 2)

  local prompt_win, prompt_opts = popup.create(message, {
    border = {},
    borderchars = conf.borderchars,
    height = 5,
    col = col,
    line = line,
    width = width,
  })

  vim.api.nvim_win_set_option(prompt_win, "winhl", "Normal:TelescopeNormal")
  vim.api.nvim_win_set_option(prompt_win, "winblend", 0)

  local prompt_border_win = prompt_opts.border and prompt_opts.border.win_id
  if prompt_border_win then
    vim.api.nvim_win_set_option(prompt_border_win, "winhl", "Normal:TelescopePromptBorder")
  end

  vim.defer_fn(vim.schedule_wrap(function()
    pcall(vim.api.nvim_win_close, prompt_win, true)
    local results = utils.get_os_command_output(command)
    callback(results)
  end), 10)
end

B.list = function(opts)
  opts = opts or {}
  opts.limit = opts.limit or 100

  -- see: https://cli.github.com/manual/gh_pr_list
  local opts_query = parse_gh_pr_opts(opts)
  local command = vim.tbl_flatten {
    "gh",
    "pr",
    "list",
    opts_query,
  }

  local title = 'Pull Request List'
  load_with_prompt('Loading ' .. title, command, function(results)
    if results[1] == '' then
      print('Empty ' .. title)
      return
    end

    pickers.new(opts, {
      prompt_title = title,
      finder = finders.new_table {
        results = results,
        entry_maker = make_entry.gen_from_string(opts),
      },
      previewer = gh_pr_p.preview.new(opts),
      sorter = conf.file_sorter(opts),
      attach_mappings = function(_, map)
        map("i", "<C-e>", gh_pr_a.checkout)
        map("n", "e", gh_pr_a.checkout)
        -- <CR> action
        actions.select_default:replace(gh_pr_a.view_web)
        return true
      end,
    }):find()
  end)
end

return B
