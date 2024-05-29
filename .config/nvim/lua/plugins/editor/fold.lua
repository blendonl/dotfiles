return {
  -- {
  --   "kevinhwang91/nvim-ufo",
  --   dependencies = {
  --     "kevinhwang91/promise-async",
  --   },
  --   event = "BufReadPost",
  --   opts = {
  --     provider_selector = function()
  --       return { "treesitter", "indent" }
  --     end,
  --   },
  --
  --   init = function()
  --     vim.keymap.set("n", "zR", function()
  --       require("ufo").openAllFolds()
  --     end)
  --     vim.keymap.set("n", "zM", function()
  --       require("ufo").closeAllFolds()
  --     end)
  --   end,
  -- },
  -- -- Folding preview, by default h and l keys are used.
  -- -- On first press of h key, when cursor is on a closed fold, the preview will be shown.
  -- -- On second press the preview will be closed and fold will be opened.
  -- -- When preview is opened, the l key will close it and open fold. In all other cases these keys will work as usual.
  -- { "anuvyklack/fold-preview.nvim", dependencies = "anuvyklack/keymap-amend.nvim", config = true },
  --
  "kevinhwang91/nvim-ufo",
  dependencies = "kevinhwang91/promise-async",

  config = function()
  	vim.o.foldcolumn = "0" -- '0' is not bad
  	vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
  	vim.o.foldlevelstart = 99
  	vim.o.foldenable = true

  	-- Using ufo provider need remap `zR` and `zM`. If Neovim is 0.6.1, remap yourself
  	vim.keymap.set("n", "zR", require("ufo").openAllFolds)
  	vim.keymap.set("n", "zM", require("ufo").closeAllFolds)
  	vim.keymap.set("n", "zM", require("ufo").closeAllFolds)

  	vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]
  	-- -- Option 1: coc.nvim as LSP client
  	-- -- use({ "nvim-treesitter/nvim-treesitter", run = ":TSUpdate" })
  	require("ufo").setup({
  		provider_selector = function(bufnr, filetype, buftype)
  			return { "treesitter", "indent" }
  		end,
  	})


  	-- Option 2: nvim lsp as LSP client
  	-- Tell the server the capability of foldingRange,
  	-- Neovim hasn't added foldingRange to default capabilities, users must add it manually
  	-- local capabilities = vim.lsp.protocol.make_client_capabilities()
  	-- capabilities.textDocument.foldingRange = {
  	-- 	dynamicRegistration = false,
  	-- 	lineFoldingOnly = true
  	-- }
  	-- local language_servers = require("lspconfig").util.available_servers() -- or list servers manually like {'gopls', 'clangd'}
  	-- for _, ls in ipairs(language_servers) do
  	-- 	require('lspconfig')[ls].setup({
  	-- 		capabilities = capabilities
  	-- 		-- you can add other fields for setting up lsp server in this table
  	-- 	})
  	-- end
  	-- require('ufo').setup()
  	--

  	-- Option 3: treesitter as a main provider instead
  	-- Only depend on `nvim-treesitter/queries/filetype/folds.scm`,
  	-- performance and stability are better than `foldmethod=nvim_treesitter#foldexpr()`
  end,
}
