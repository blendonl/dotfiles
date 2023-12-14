local map = vim.keymap.set
-- buffers
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })

map("n", "<leader>bd", function(n)
	require("mini.bufremove").delete(n, false)
end, { desc = "mark file" })
