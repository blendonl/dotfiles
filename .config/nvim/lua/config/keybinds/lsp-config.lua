vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", {}),
	callback = function(ev)
		local buf = ev.buf
		local map = function(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
		end

		vim.bo[buf].omnifunc = "v:lua.vim.lsp.omnifunc"

		map("n", "K", vim.lsp.buf.hover, "hover")
		map("n", "gD", vim.lsp.buf.declaration, "go to declaration")
		map("n", "gd", vim.lsp.buf.definition, "go to definition")
		map("n", "gr", vim.lsp.buf.references, "go to reference")
		map("n", "gt", function()
			require("trouble").toggle("lsp_references")
		end, "go to trouble")
		map("n", "gi", vim.lsp.buf.implementation, "go to implementation")
		map("n", "gS", vim.lsp.buf.signature_help, "signature help")
		map("n", "g[", vim.diagnostic.open_float, "diagnostics float")

		map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, "add workspace folder")
		map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, "remove workspace folder")
		map("n", "<leader>wl", function()
			print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
		end, "list workspace folders")

		map("n", "<leader>cD", vim.lsp.buf.type_definition, "type definition")
		map("n", "<leader>cr", vim.lsp.buf.rename, "rename")
		map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "code action")
		map("n", "<leader>cf", function()
			vim.lsp.buf.format({ async = true })
		end, "format code")

		map("n", "<space>xw", function()
			for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
				require("workspace-diagnostics").populate_workspace_diagnostics(client, buf)
			end
		end, "populate workspace diagnostics")

		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		if client and client:supports_method("textDocument/inlayHint") then
			vim.lsp.inlay_hint.enable(true, { bufnr = buf })
			map("n", "<leader>ch", function()
				vim.lsp.inlay_hint.enable(
					not vim.lsp.inlay_hint.is_enabled({ bufnr = buf }),
					{ bufnr = buf }
				)
			end, "toggle inlay hints")
		end
	end,
})
