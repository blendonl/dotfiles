-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", {}),
	callback = function(ev)
		-- Enable completion triggered by <c-x><c-o>
		vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

		-- Buffer local mappings.
		-- See `:help vim.lsp.*` for documentation on any of the below functions
		vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = ev.buf, desc = "hover" })
		vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { buffer = ev.buf, desc = "go to declaration" })
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = ev.buf, desc = "go to definition" })
		vim.keymap.set("n", "gr", vim.lsp.buf.references, { buffer = ev.bu, desc = "go to refrence" })
		vim.keymap.set("n", "gR", function() require("trouble").toggle("lsp_references") end)
		vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { buffer = ev.buf, desc = "go to implementation" })
		vim.keymap.set("n", "gs", vim.lsp.buf.signature_help, { buffer = ev.buf, desc = "signature help" })
		vim.keymap.set("n", "gl", vim.diagnostic.open_float, { buffer = ev.buf, desc = "list diagnostics float" })

		vim.keymap.set(
			"n",
			"<leader>wa",
			vim.lsp.buf.add_workspace_folder,
			{ buffer = ev.bu, desc = "add workspace folder" }
		)
		vim.keymap.set(
			"n",
			"<leader>wr",
			vim.lsp.buf.remove_workspace_folder,
			{ buffer = ev.bu, desc = "remove workspace folder" }
		)
		vim.keymap.set("n", "<leader>wl", function()
			print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
		end, { buffer = ev.bu, desc = "list workspace folders" })
		vim.keymap.set("n", "<leader>cD", vim.lsp.buf.type_definition, { buffer = ev.bu, desc = "type definition" })
		vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, { buffer = ev.bu, desc = "rename" })

		vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { buffer = ev.bu, desc = "code action" })
		vim.keymap.set("n", "<leader>cf", function()
			vim.lsp.buf.format({ async = true })
		end, { buffer = ev.bu, desc = "format code" })
	end,
})
