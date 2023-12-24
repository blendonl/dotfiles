local map = vim.keymap.set
local trouble = require('trouble')



map('n', "<leader>xx", "<cmd>TroubleToggle document_diagnostics<cr>", { desc = "Document Diagnostics (Trouble)" })
map('n', "<leader>xX", "<cmd>TroubleToggle workspace_diagnostics<cr>", { desc = "Workspace Diagnostics (Trouble)" })
map('n', "<leader>xL", "<cmd>TroubleToggle loclist<cr>", { desc = "Location List (Trouble)" })
map('n', "<leader>xQ", "<cmd>TroubleToggle quickfix<cr>", { desc = "Quickfix List (Trouble)" })
map('n',
	"[q",
	function()
		if trouble.is_open() then
			trouble.previous({ skip_groups = true, jump = true })
		else
			local ok, err = pcall(vim.cmd.cprev)
			if not ok then
				vim.notify(err, vim.log.levels.ERROR)
			end
		end
	end,
	{ desc = "Previous trouble/quickfix item" })
map('n',
	"]q",
	function()
		if trouble.is_open() then
			trouble.next({ skip_groups = true, jump = true })
		else
			local ok, err = pcall(vim.cmd.cnext)
			if not ok then
				vim.notify(err, vim.log.levels.ERROR)
			end
		end
	end,
	{ desc = "Next trouble/quickfix item"
	})
