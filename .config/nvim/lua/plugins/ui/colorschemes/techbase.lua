return {
	"mcauley-penney/techbase.nvim",
	options = {
		techbase_dark = true,
		techbase_italic_comments = true,
		techbase_transparent = false,

	},
	config = function()
		vim.cmd.colorscheme("techbase")
	end,
	priority = 1000
}
