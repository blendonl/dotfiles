return {
  {
    -- Theme inspired by Atom
    'nordtheme/vim',
    priority = 1000,
    -- config = function()
    --   vim.cmd.colorscheme 'nord'
    -- end,
  },
  {
    "catppuccin/nvim",
    lazy = false,
    name = "catppuccin",
    opts = {
      integrations = {
        aerial = true,
        alpha = true,
        cmp = true,
        dashboard = true,
        flash = true,
        gitsigns = true,
        headlines = true,
        illuminate = true,
        indent_blankline = { enabled = true },
        leap = true,
        lsp_trouble = true,
        mason = true,
        markdown = true,
        mini = true,
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
        navic = { enabled = true, custom_bg = "lualine" },
        neotest = true,
        neotree = true,
        noice = true,
        notify = true,
        semantic_tokens = true,
        telescope = true,
        treesitter = true,
        treesitter_context = true,
        which_key = true,
      },
    },
    config = function()
      -- vim.cmd.colorscheme 'catppuccin-mocha'
    end
  },
  {
    'rebelot/kanagawa.nvim',
    opts = {},
    config = function()
    end,
  },
  {
    'AlexvZyl/nordic.nvim',
    opts = {},
    config = function()
    end,
  },

  {
    'bluz71/vim-moonfly-colors',
    opts = {},
    config = function()
    end,
  },
  {
    'bluz71/vim-nightfly-colors',
    opts = {},
    config = function()
    end,
  },
  {
    'marko-cerovac/material.nvim',
    opts = {},
    config = function()
    end,
  },
  {
    'olimorris/onedarkpro.nvim',
    opts = {},
    config = function()
    end,
  },

  {
    'projekt0n/github-nvim-theme',
    opts = {},
    config = function()
    end,
  },

  {
    'morhetz/gruvbox',
    opts = {},
    config = function()
      vim.cmd.colorscheme 'nord'
    end,
  }
}
