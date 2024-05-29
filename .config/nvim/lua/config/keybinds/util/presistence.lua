local map = vim.keymap.set
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit all" })

-- map('n', "<leader>qs", function() require("persistence").load() end, { desc = "Restore Session" })
-- map('n', "<leader>ql", function() require("persistence").load({ last = true }) end, { desc = "Restore Last Session" })
-- map('n', "<leader>qd", function() require("persistence").stop() end, { desc = "Don't Save Current Session" })
