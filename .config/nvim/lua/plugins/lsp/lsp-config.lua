return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"j-hui/fidget.nvim",
			"folke/neodev.nvim",
		},
		config = function()
			-- require("lspconfig").eslintd.setup({
			-- 	on_attach = function(client, bufnr)
			-- 		require("workspace-diagnostics").populate_workspace_diagnostics(client, bufnr)
			-- 	end,
			-- })

			require("lspconfig").lua_ls.setup({
				settings = {
					Lua = {
						diagnostics = {
							globals = { "vim" },
						},
					},
				},
			})
		end,
	},
}
