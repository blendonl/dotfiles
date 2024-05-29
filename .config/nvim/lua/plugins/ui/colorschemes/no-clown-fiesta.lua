return {
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
			vim.cmd("highlight Normal guibg='#000000' guifg=white")
			vim.o.background = "dark"
		end,
	},
}
