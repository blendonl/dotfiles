return {
	{
		"nvim-pack/nvim-spectre",
		build = false,
		cmd = "Spectre",
		keys = {
			{
				"<leader>sr",
				function()
					require("spectre").open()
				end,
				desc = "Search and Replace (Spectre)",
			},
		},
		opts = { open_cmd = "noswapfile vnew" },
	},
}
