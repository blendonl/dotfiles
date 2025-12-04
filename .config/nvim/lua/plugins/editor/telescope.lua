return {
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {

			"A7Lavinraj/fyler.nvim",
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
			},
		},
		cmd = "Telescope",
		opts = function()
			local telescope = require("telescope")
			telescope.setup({
				defaults = {
					file_ignore_patterns = {
						".cache",
						"dist",
						"node_modules",
						"yarn.lock",
						"vendors/prisma",
					},
					extensions = {
						fzf = {},
					},

					-- layout_config = {
					-- 	width = 0.6,
					-- 	height = 0.7,
					-- },
				},
			})

			telescope.load_extension("rest")
			-- telescope.load_extension("fyler_zoxide")
			telescope.load_extension("harpoon")
			-- telescope.load_extension("fzf")

			require("config.telescope-multi-grep").setup()
			return telescope
		end,
	},
}
