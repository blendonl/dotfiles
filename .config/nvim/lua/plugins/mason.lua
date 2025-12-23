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
		config = function()
			local mason_lspconfig = require("mason-lspconfig")
			mason_lspconfig.setup({
				automatic_enable = true,
				ensure_installed = {
					"lua_ls",
				},
			})
		end,
	},
}
