return {
	"artemave/workspace-diagnostics.nvim",
	config = function()
		require("workspace-diagnostics").setup({
			workspace_files = function()
				return vim.fn.split(
					vim.fn.system("git ls-files "),
					"\n"
				)
			end,
		})

		-- require("lspconfig").tsserver.setup({
		-- 	on_attach = function(client, bufnr)
		-- 		require("workspace-diagnostics").populate_workspace_diagnostics(client, bufnr)
		-- 	end,
		-- })
	end,
}
