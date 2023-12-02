return {
	{
		-- Theme inspired by Atom
		"nordtheme/vim",
		priority = 1000,
		config = function()
			vim.cmd.colorscheme("nord")
			vim.cmd("highlight Normal guibg='#0f0f0f' guifg=white")
			vim.o.backgrounds = "dark"
		end,
	},
	{
		"catppuccin/nvim",
		lazy = false,
		name = "catppuccin",
		opts = {
			background = { -- :h background
				light = "dark",
				dark = "mocha",
			},
			transparent_background = false, -- disables setting the background color.
			show_end_of_buffer = false, -- shows the '~' characters after the end of buffers
			term_colors = false, -- sets terminal colors (e.g. `g:terminal_color_0`)
			dim_inactive = {
				enabled = true, -- dims the background color of inactive window
				shade = "dark",
				percentage = 1, -- percentage of the shade to apply to the inactive window
			},
			no_italic = false, -- Force no italic
			no_bold = false, -- Force no bold
			no_underline = false, -- Force no underline
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
		},
		config = function()
			require("catppuccin").setup({
				styles = { -- Handles the styles of general hi groups (see `:h highlight-args`):
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
						base = "#18191A",
						mantle = "#242526",
						crust = "#474747",
					},
					latte = {},
					frappe = {},
					macchiato = {},
					mocha = {},
				},
			})
			vim.cmd.colorscheme("catppuccin-mocha")
		end,
	},
	{
		"aktersnurra/no-clown-fiesta.nvim",
		opts = {

			transparent = false, -- Enable this to disable the bg color
			styles = {
				-- You can set any of the style values specified for `:h nvim_set_hl`
				comments = { "italic" },
				keywords = { "italic" },
				functions = { "italic" },
				variables = { "italic" },
				type = { bold = true },
				lsp = { underline = true },
			},
		},
		config = function()
			-- vim.cmd.colorscheme("no-clown-fiesta")
		end,
	},
}
