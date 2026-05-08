return {
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		build = ":MasonUpdate",
		opts = {},
	},
	"neovim/nvim-lspconfig",
	{
		"williamboman/mason-lspconfig.nvim",
		opts = {
			-- vim.lsp.enable(...) in lua/config/lsp.lua is the source of truth
			automatic_enable = false,
			ensure_installed = {
				"lua_ls",
				"vtsls",
				"cssls",
				"html",
				"jsonls",
			},
		},
	},
}
