return {
	"epwalsh/obsidian.nvim",
	version = "*", -- recommended, use latest release instead of latest commit
	lazy = true,
	ft = "markdown",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope.nvim",
		"preservim/vim-markdown",
		"epwalsh/pomo.nvim",
	},
	opts = {
		workspaces = {
			{
				name = "personal",
				path = "/home/notpc/notes/personal",
			},
			{
				name = "work",
				path = "/home/notpc/notes/work",
			},
			{
				name = "general",
				path = "/home/notpc/notes/general",
			},
			{
				name = "all",
				path = "/home/notpc/notes",
			},
		}, -- Optional, configure key mappings. These are the defaults. If you don't want to set any keymappings this
		mappings = {
			-- Overrides the 'gf' mapping to work on markdown/wiki links within your vault.
			["gf"] = {
				action = function()
					return require("obsidian").util.gf_passthrough()
				end,
				opts = { noremap = false, expr = true, buffer = true },
			},
			-- Toggle check-boxes.
			["<leader>oc"] = {
				action = function()
					return require("obsidian").util.toggle_checkbox()
				end,
				opts = { buffer = true },
			},
			-- Toggle check-boxes.
			["<leader>osq"] = {
				action = "<cmd>ObsidianQuickSwitch<cr>",
				opts = { buffer = true },
			},
			["<leader>osd"] = {
				action = "<cmd>ObsidianDailies<cr>",
				opts = { buffer = true },
			},
			["<leader>otd"] = {
				action = "<cmd>ObsidianToday<cr>",
				opts = { buffer = true },
			},
			["<leader>otm"] = {
				action = "<cmd>ObsidianTomorrow<cr>",
				opts = { buffer = true },
			},
			-- Smart action depending on context, either follow link or toggle checkbox.
			["<cr>"] = {
				action = function()
					return require("obsidian").util.smart_action()
				end,
				opts = { buffer = true, expr = true },
			},
		},

		-- see below for full list of options 👇
	},
}
