return {
	{
		"catppuccin/nvim",
		lazy = false,
		name = "catppuccin",
		config = function()
			require("catppuccin").setup({
				background = { -- :h background
					dark = "mocha",
				},
				transparent_background = false, -- disables setting the background color.
				show_end_of_buffer = false, -- shows the '~' characters after the end of buffers
				term_colors = true,         -- sets terminal colors (e.g. `g:terminal_color_0`)
				dim_inactive = {
					enabled = true,           -- dims the background color of inactive window
					shade = "dark",
					percentage = 1,           -- percentage of the shade to apply to the inactive window
				},
				no_italic = false,          -- Force no italic
				no_bold = false,            -- Force no bold
				no_underline = false,       -- Force no underline
				integrations = {
					aerial = true,
					alpha = true,
					cmp = true,
					dashboard = true,
					flash = true,
					gitsigns = true,
					headlines = true,
					illuminate = true,
					indent_blankline = { enabled = true },
					leap = true,
					lsp_trouble = true,
					mason = true,
					markdown = true,
					mini = true,
					native_lsp = {
						enabled = true,
						underlines = {
							errors = { "undercurl" },
							hints = { "undercurl" },
							warnings = { "undercurl" },
							information = { "undercurl" },
						},
					},
					navic = { enabled = true, custom_bg = "lualine" },
					neotest = true,
					neotree = true,
					noice = true,
					notify = true,
					semantic_tokens = true,
					telescope = true,
					treesitter = true,
					treesitter_context = true,
					which_key = true,
				},
				styles = {            -- Handles the styles of general hi groups (see `:h highlight-args`):
					comments = { "italic" }, -- Change the style of comments
					conditionals = { "italic" },
					loops = {},
					functions = {},
					keywords = { "italic", "bold" },
					strings = { "italic" },
					variables = {},
					numbers = {},
					booleans = { "italic" },
					properties = {},
					types = {},
					operators = { "italic", "bold" },
				},

				color_overrides = {
					all = {
						base = "#000000",
						mantle = "#0f0f0f",
						crust = "#101010",
					},
					latte = {},
					frappe = {},
					macchiato = {},
					mocha = {},
				},
			})
			-- vim.cmd.colorscheme("catppuccin-mocha")
		end,
	},
}
