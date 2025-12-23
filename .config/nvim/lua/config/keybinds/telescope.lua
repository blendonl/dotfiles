local telescope = require("telescope.builtin")

local function telescope_live_grep_open_files()
	telescope.live_grep({
		grep_open_files = true,
		prompt_title = "Live Grep in Open Files",
	})
end

vim.keymap.set("n", "<leader>?", telescope.oldfiles, { desc = "[?] Find recently opened files" })
vim.keymap.set("n", "<leader><space>", function()
	telescope.buffers({ ignore_current_buffer = true, sort_lastused = true, sort_mru = true })
end, { desc = "[ ] Find existing buffers" })
vim.keymap.set("n", "<leader>/", telescope.current_buffer_fuzzy_find, { desc = "[/] Fuzzily search in current buffer" })
vim.keymap.set("n", "<leader>s/", telescope_live_grep_open_files, { desc = "[S]earch [/] in Open Files" })
vim.keymap.set("n", "<leader>sa", telescope.builtin, { desc = "[S]earch [S]elect Telescope" })
vim.keymap.set("n", "<leader>sgf", telescope.git_files, { desc = "Search [G]it [F]iles" })
vim.keymap.set("n", "<leader>sf", function()
	telescope.find_files({
		hidden = true,
		no_ignore = true,
		no_ignore_parent = true,
	})
end, { desc = "[S]earch [F]iles" })

vim.keymap.set("n", "<leader>ss", function()
	telescope.find_files({
		cwd = "./src",
		hidden = true,
		no_ignore = true,
		no_ignore_parent = true,
	})
end, { desc = "[S]earch Files [S]rc" })

vim.keymap.set("n", "<leader>sh", telescope.help_tags, { desc = "[S]earch [H]elp" })
vim.keymap.set("n", "<leader>sw", telescope.grep_string, { desc = "[S]earch current [W]ord" })
vim.keymap.set("n", "<leader>sgg", telescope.live_grep, { desc = "[S]earch by [G]rep" })
vim.keymap.set("n", "<leader>sd", telescope.diagnostics, { desc = "[S]earch [D]iagnostics" })
vim.keymap.set("n", "<leader>sr", telescope.resume, { desc = "[S]earch [R]esume" })
vim.keymap.set("n", "<leader>sk", telescope.keymaps, { desc = "[S]earch [K]eymaps" })
vim.keymap.set("n", "<leader>sc", function()
	telescope.colorscheme({
		enable_preview = true,
	})
end, { desc = "[S]earch [K]eymaps" })
