local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'
local job = require 'plenary.job'

local DEFAULT_OPTIONS = {
  default_remote = 'origin',
  default_branches = {
    'main',
    'master',
    'develop',
  },
}

local A = {}

local function run(command)
  local handle = io.popen(command)
  if handle ~= nil then
    local result = handle:read("*a")
    handle:close()

    return string.gsub(result, '\n', ' ')
  end
end

local function remote_base_url()
  local git_remote_url = run('git ls-remote --get-url ' .. DEFAULT_OPTIONS.default_remote)
  local url_base = string.gsub(git_remote_url, '^.-github.com[:/]?(.*)%.git%s?$', '%1')

  if git_remote_url == url_base or #url_base <= 0 then
    error('fatal: could not open remote url about \'' .. git_remote_url .. '\'')
  end

  return url_base
end

local function close_telescope_prompt(bufnr)
  local selection = action_state.get_selected_entry()

  actions.close(bufnr)

  local tmp_table = vim.split(selection.value, '\t')
  if vim.tbl_isempty(tmp_table) then
    return
  end

  return tmp_table[1]
end

local function checkout_pr_by_qf_action(pr_number)
  local qf_entry = {
    {
      text = 'Checking out pull request #' .. pr_number .. ', please wait ...',
    },
  }
  local on_output = function(_, line)
    table.insert(qf_entry, {
      text = line,
    })
    pcall(vim.schedule_wrap(function()
      vim.fn.setqflist(qf_entry, 'r')
    end))
  end

  local instance = job:new{
    enable_recording = true,
    command = 'gh',
    args = vim.tbl_flatten {
      'pr',
      'checkout',
      pr_number,
      '-b',
      'pr/' .. pr_number,
      '-f',
    },
    on_stdout = on_output,
    on_stderr = on_output,
    on_exit = function(_, status)
      if status == 0 then
        pcall(vim.schedule_wrap(function()
          vim.cmd [[cclose]]
        end))
        print('Pull request completed')
      end
    end,
  }

  vim.fn.setqflist(qf_entry, 'r')
  vim.cmd [[copen]]

  local timer = vim.loop.new_timer()
  timer:start(200, 0, vim.schedule_wrap(function()
    instance:sync()
  end))
end

A.checkout = function(bufnr)
  local pr_number = close_telescope_prompt(bufnr)

  if pr_number == nil then
    return
  end

  checkout_pr_by_qf_action(pr_number)
end

A.view_web = function(bufnr)
  local pr_number = close_telescope_prompt(bufnr)

  if pr_number == nil then
    return
  end

  -- bug: fork/exec /usr/bin/open: bad file descriptor
  -- os.execute('gh pr view --web ' .. pr_number)
  -- open only github pull
  os.execute('open https://github.com/' .. remote_base_url() .. '/pull/' .. pr_number)
end

return A
