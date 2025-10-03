local map = vim.keymap.set
map("n", "<leader>hm", function()
	require("harpoon.mark").add_file()
end, { desc = "mark file" })

map("n", "<leader>hc", function()
	require("harpoon.mark").clear_all()
end, { desc = "clear all marked files" })

map("n", "<leader>hh", function()
	require("harpoon.ui").toggle_quick_menu()
end, { desc = "list mark file" })

map("n", "<A-1>", function()
	require("harpoon.ui").nav_file(1)
end, { desc = "get marked file 1" })

map("n", "<A-2>", function()
	require("harpoon.ui").nav_file(2)
end, { desc = "get marked file 1" })

map("n", "<A-3>", function()
	require("harpoon.ui").nav_file(3)
end, { desc = "get marked file 1" })

map("n", "<A-4>", function()
	require("harpoon.ui").nav_file(4)
end, { desc = "get marked file 1" })

map("n", "<C-n>", function()
	require("harpoon.ui").nav_next() -- navigates to next mark
end, { desc = "get next" })

map("n", "<C-p>", function()
	require("harpoon.ui").nav_prev() -- navigates to next mark
end, { desc = "get prev" })
