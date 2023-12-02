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
}
