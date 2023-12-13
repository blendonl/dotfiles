return {
	-- NOTE: This is where your plugins related to LSP can be installed.
	--  The configuration is done below. Search for lspconfig to find it below.
	{

		"williamboman/mason.nvim",
		cmd = "Mason",
		keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
		build = ":MasonUpdate",
		opts = {},
	},
}
