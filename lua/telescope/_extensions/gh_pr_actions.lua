local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local job = require "plenary.job"

local A = {}

local function close_telescope_prompt(bufnr)
  actions.close(bufnr)

  local selection = action_state.get_selected_entry()
  local tmp_table = vim.split(selection.value, "\t")

  if vim.tbl_isempty(tmp_table) then
    return
  end

  return tmp_table[1]
end

local function pr_job_with_qf_action(pr_number, action, message)
  if pr_number == nil then
    return
  end
  local qf_entry = {
    {
      text = message .. pr_number .. ", please wait ...",
    },
  }
  local on_output = function(_, line)
    table.insert(qf_entry, {
      text = line,
    })
    pcall(vim.schedule_wrap(function()
      vim.fn.setqflist(qf_entry, "r")
    end))
  end

  local instance = job:new{
    enable_recording = true,
    command = "gh",
    args = vim.tbl_flatten {
      "pr",
      action,
      pr_number,
    },
    on_stdout = on_output,
    on_stderr = on_output,
    on_exit = function(_, status)
      if status == 0 then
        pcall(vim.schedule_wrap(function()
          vim.cmd [[cclose]]
        end))
        print "Pull request completed"
      end
    end,
  }

  vim.fn.setqflist(qf_entry, "r")
  vim.cmd [[copen]]

  local timer = vim.loop.new_timer()
  timer:start(200, 0, vim.schedule_wrap(function()
    instance:sync()
  end))
end

A.checkout = function(bufnr)
  local pr_number = close_telescope_prompt(bufnr)
  pr_job_with_qf_action(pr_number, "checkout", "Checking out pull request #")
end

A.view_web = function()
  return function(bufnr)
    actions.close(bufnr)

    local selection = action_state.get_selected_entry()
    local tmp_table = vim.split(selection.value, "\t")

    if vim.tbl_isempty(tmp_table) then
      return
    end

    os.execute("gh pr view --web " .. tmp_table[1])
  end
end

return A
