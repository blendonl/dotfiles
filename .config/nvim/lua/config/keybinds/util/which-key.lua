local whichkey = require("which-key")

whichkey.add({

	{ "<leader>b", group = "[B]uffer" },
	{ "<leader>b_", hidden = true },
	{ "<leader>c", group = "[C]ode" },
	{ "<leader>c_", hidden = true },
	{ "<leader>d", group = "[D]ocument" },
	{ "<leader>d_", hidden = true },
	{ "<leader>f", group = "[F]ile" },
	{ "<leader>f_", hidden = true },
	{ "<leader>g", group = "[G]it" },
	{ "<leader>g_", hidden = true },
	{ "<leader>h", group = "[H]arpoon" },
	{ "<leader>h_", hidden = true },
	{ "<leader>q", group = "[Q]session" },
	{ "<leader>q_", hidden = true },
	{ "<leader>r", group = "[R]ename" },
	{ "<leader>r_", hidden = true },
	{ "<leader>s", group = "[S]earch" },
	{ "<leader>s_", hidden = true },
	{ "<leader>t", group = "[T]oggle" },
	{ "<leader>t_", hidden = true },
	{ "<leader>u", group = "[U]i" },
	{ "<leader>u_", hidden = true },
	{ "<leader>w", group = "[W]orkspace" },
	{ "<leader>w_", hidden = true },
	{ "<leader>x", group = "[X]lists" },
	{ "<leader>x_", hidden = true },
})

whichkey.add({
	{ "<leader>", group = "VISUAL <leader>", mode = "v" },
	{ "<leader>h", desc = "Git [H]unk", mode = "v" },
}, { mode = "v" })
