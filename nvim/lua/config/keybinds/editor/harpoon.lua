local map = vim.keymap.set
map("n", "<leader>hm", function()
	require("harpoon.mark").add_file()
end, { desc = "mark file" })

map("n", "<leader>hh", function()
	require("harpoon.ui").toggle_quick_menu()
end, { desc = "mark file" })
