local map = vim.keymap

map.set("n", "<leader>tt", function()
	require("twilight").toggle()
end, { desc = "toggle twilight" })
