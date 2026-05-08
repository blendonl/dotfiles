return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")

      ts.setup({
        install_dir = vim.fn.stdpath("data") .. "/site",
      })

      local parsers = {
        "bash", "c", "cpp", "css", "diff", "go",
        "html", "javascript", "json", "jsonc", "lua", "luadoc", "luap",
        "markdown", "markdown_inline", "python", "query", "regex", "rust",
        "toml", "tsx", "typescript", "vim", "vimdoc", "yaml",
      }

      local installed = ts.get_installed("parsers")
      local installed_set = {}
      for _, p in ipairs(installed) do installed_set[p] = true end

      local missing = {}
      for _, p in ipairs(parsers) do
        if not installed_set[p] then table.insert(missing, p) end
      end
      if #missing > 0 then ts.install(missing) end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("UserTreesitter", {}),
        callback = function(ev)
          local lang = vim.treesitter.language.get_lang(vim.bo[ev.buf].filetype)
          if not lang then return end
          if not pcall(vim.treesitter.start, ev.buf, lang) then return end
          vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },
}
