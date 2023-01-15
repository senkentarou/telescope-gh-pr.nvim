local previewers = require "telescope.previewers"
local utils = require "telescope.utils"
local defaulter = utils.make_default_callable
local putils = require "telescope.previewers.utils"

local P = {}

P.preview = defaulter(function(opts)
  return previewers.new_buffer_previewer {
    get_buffer_by_name = function(_, entry)
      return entry.value
    end,

    define_preview = function(self, entry, _)
      local tmp_table = vim.split(entry.value, "\t")
      local command = {
        "gh",
        "pr",
        "view",
        tmp_table[1],
      }
      local filetype = "markdown"

      putils.job_maker(command, self.state.bufnr, {
        value = entry.value .. filetype,
        bufname = self.state.bufname,
        cwd = opts.cwd,
      })
      putils.regex_highlighter(self.state.bufnr, filetype)
    end,
  }
end, {})

return P
