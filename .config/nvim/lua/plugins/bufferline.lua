return {
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons", "echasnovski/mini.bufremove" },
    keys = {
      { "<S-h>",      "<Cmd>BufferLineCyclePrev<CR>",    desc = "Prev buffer" },
      { "<S-l>",      "<Cmd>BufferLineCycleNext<CR>",    desc = "Next buffer" },
      { "[b",         "<Cmd>BufferLineCyclePrev<CR>",    desc = "Prev buffer" },
      { "]b",         "<Cmd>BufferLineCycleNext<CR>",    desc = "Next buffer" },
      { "<leader>b[", "<Cmd>BufferLineMovePrev<CR>",     desc = "Move buffer left" },
      { "<leader>b]", "<Cmd>BufferLineMoveNext<CR>",     desc = "Move buffer right" },
      { "<leader>bj", "<Cmd>BufferLinePick<CR>",         desc = "Jump to buffer" },
      { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>",    desc = "Toggle pin" },
      { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete unpinned buffers" },
      { "<leader>bl", "<Cmd>BufferLineCloseRight<CR>",   desc = "Delete buffers to the right" },
      { "<leader>bh", "<Cmd>BufferLineCloseLeft<CR>",    desc = "Delete buffers to the left" },
    },
    opts = {
      options = {
        -- Buffers, not tabpages: every buffer lives on the one tabline.
        mode = "buffers",
        close_command = function(n) require("mini.bufremove").delete(n, false) end,
        right_mouse_command = function(n) require("mini.bufremove").delete(n, false) end,
        diagnostics = "nvim_lsp",
        diagnostics_indicator = function(_, _, diag)
          local icons = { Error = " ", Warn = " ", Info = " " }
          local ret = (diag.error and icons.Error .. diag.error .. " " or "")
              .. (diag.warning and icons.Warn .. diag.warning or "")
          return vim.trim(ret)
        end,
        offsets = {
          {
            filetype = "neo-tree",
            text = "Explorer",
            highlight = "Directory",
            text_align = "left",
          },
        },
        -- Scrolling: keep the buffer list one long strip that slides under the
        -- window instead of shrinking every name to fit.
        always_show_bufferline = true,
        enforce_regular_tabs = false,
        tab_size = 0,
        max_name_length = 30,
        truncate_names = false,
        separator_style = "thin",
        show_buffer_close_icons = true,
        show_close_icon = false,
        -- Arrows on both ends mark that more buffers exist off-screen.
        left_trunc_marker = "",
        right_trunc_marker = "",
        -- Jump the strip so the current buffer is never off-screen.
        sort_by = "insert_after_current",
      },
    },
    config = function(_, opts)
      require("bufferline").setup(opts)
      -- Redraw after session load / buffer wipeout so the strip stays in sync.
      vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
        callback = function()
          vim.schedule(function() pcall(vim.cmd.redrawtabline) end)
        end,
      })
    end,
  },
}
