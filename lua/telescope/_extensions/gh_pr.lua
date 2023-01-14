local builtin = require('telescope._extensions.gh_pr_builtin')

return require('telescope').register_extension {
  exports = {
    list = builtin.list,
  },
}
