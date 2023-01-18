# Telescope-gh-pr.nvim
* This is an integration with [github cli](https://cli.github.com/) and [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

## Installation

* vim-plug
```
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'senkentarou/telescope-gh-pr.nvim'
```

## Setup
* Please setup as telescope extension on `init.lua` as below:
```
local telescope = require("telescope")

telescope.setup {
  ...
}

telescope.load_extension("gh_pr")
```

## Commands
```
:Telescope gh_pr list

-- Using lua function
:lua require('telescope').extensions.gh_pr.list()
```

## For development
* First, you need to do the setup section.

* And load under development plugin files on root repository.
  * (If you already installed this plugin thankfully, please comment out applying code before.)

```
nvim --cmd "set rtp+=."
```

## License
* MIT

## Special thanks
* This plugin was inspired by [telescope-github.nvim](https://github.com/nvim-telescope/telescope-github.nvim)
