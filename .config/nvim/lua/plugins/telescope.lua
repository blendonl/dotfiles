return {
	{ 'nvim-telescope/telescope-fzf-native.nvim', build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release --target install' },

	{
		"nvim-telescope/telescope.nvim",
		dependencies = {

			"A7Lavinraj/fyler.nvim",
			"nvim-lua/plenary.nvim",
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
						fzf = {
							fuzzy = true,            -- false will only do exact matching
							override_generic_sorter = true, -- override the generic sorter
							override_file_sorter = true, -- override the file sorter
							case_mode = "smart_case", -- or "ignore_case" or "respect_case"
							-- the default case_mode is "smart_case"
						}
					},

					-- layout_config = {
					-- 	width = 0.6,
					-- 	height = 0.7,
					-- },
				},
			})

			telescope.load_extension("rest")
			-- telescope.load_extension("fyler_zoxide")
			telescope.load_extension("fzf")

			require("config.telescope-multi-grep").setup()
			return telescope
		end,
	},
	{
		"zerochae/endpoint.nvim",
		keys = {
			{ "<leader>ee", "<cmd>Endpoint<cr>",      desc = "REST Endpoints" },
			{ "<leader>ep", "<cmd>Endpoint POST<cr>", desc = "REST Endpoints" },
		},
		dependencies = {
			-- Choose one or more pickers (all optional):
			"nvim-telescope/telescope.nvim", -- For telescope picker
			"folke/snacks.nvim",          -- For snacks picker
			"stevearc/dressing.nvim",     -- Enhances vim.ui.select with telescope backend
			-- vim.ui.select picker works without dependencies
		},
		cmd = { "Endpoint", "EndpointRefresh" },
		config = function()
			require("endpoint").setup()
		end,
	}

}
