local whichkey = require("which-key")

whichkey.register({
	["<leader>b"] = { name = "[B]uffer", _ = "which_key_ignore" },
	["<leader>c"] = { name = "[C]ode", _ = "which_key_ignore" },
	["<leader>d"] = { name = "[D]ocument", _ = "which_key_ignore" },
	["<leader>f"] = { name = "[F]ile", _ = "which_key_ignore" },
	["<leader>g"] = { name = "[G]it", _ = "which_key_ignore" },
	["<leader>h"] = { name = "[H]arpoon", _ = "which_key_ignore" },
	["<leader>r"] = { name = "[R]ename", _ = "which_key_ignore" },
	["<leader>n"] = { name = "[N]oice", _ = "which_key_ignore" },
	["<leader>s"] = { name = "[S]earch", _ = "which_key_ignore" },
	["<leader>t"] = { name = "[T]oggle", _ = "which_key_ignore" },
	["<leader>q"] = { name = "[Q]session", _ = "which_key_ignore" },
	["<leader>u"] = { name = "[U]i", _ = "which_key_ignore" },
	["<leader>w"] = { name = "[W]orkspace", _ = "which_key_ignore" },
	["<leader>x"] = { name = "[X]lists", _ = "which_key_ignore" },
})

whichkey.register({
	["<leader>"] = { name = "VISUAL <leader>" },
	["<leader>h"] = { "Git [H]unk" },
}, { mode = "v" })
