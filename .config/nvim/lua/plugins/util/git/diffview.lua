return {
	{
		"sindrets/diffview.nvim",
		cmd = "DiffviewOpen",
		keys = {
			{ "<leader>gvoo", "<cmd>DiffviewOpen<CR>", desc = "Toggle diff view" },
			{ "<leader>gvc", "<cmd>DiffviewClose<CR>", desc = "Toggle diff view" },
			{ "<leader>gvoc", "<cmd>DiffviewOpen --selected-file<CR>", desc = "Toggle diff view" },
		},
		opts = {},
	},
}
