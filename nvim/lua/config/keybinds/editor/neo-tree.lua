local map = vim.keymap.set
-- map("n", "<leader>fe", function()
-- 	require("neo-tree.command").execute({ toggle = true, dir = require("lazyvim.util").root() })
-- end, { desc = "Explorer NeoTree (root dir)" })
map("n", "<leader>fE", function()
	require("neo-tree.command").execute({ toggle = true, dir = vim.loop.cwd() })
end, { desc = "Explorer NeoTree (cwd)" })
map("n", "<leader>e", "<leader>fe", { desc = "Explorer NeoTree (root dir)", remap = true })
map("n", "<leader>E", "<leader>fE", { desc = "Explorer NeoTree (cwd)", remap = true })
map("n", "<leader>be", function()
	require("neo-tree.command").execute({ source = "buffers", toggle = true })
end, { desc = "Buffer explorer" })
