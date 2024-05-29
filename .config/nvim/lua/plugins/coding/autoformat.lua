return {
	{
		"stevearc/conform.nvim",
		dependencies = { "mason.nvim" },
		event = { "BufReadPre", "BufNewFile" },
		cmd = "ConformInfo",
		keys = {
			{
				"<leader>cF",
				function()
					require("conform").format({ formatters = { "injected" } })
				end,
				mode = { "n", "v" },
				desc = "Format Injected Langs",
			},
		},
		config = function()
			local conform = require("conform")
			conform.setup({
				formatters_by_ft = {
					javascript = { "prettier" },
					typescript = { "prettier" },
					javascriptreact = { "prettier" },
					typescriptreact = { "prettier" },
					svelte = { "prettier" },
					css = { "prettier" },
					html = { "prettier" },
					json = { "prettier" },
					yaml = { "prettier" },
					markdown = { "prettier" },
					graphql = { "prettier" },
					lua = { "stylua" },
					python = { "isort", "black" },
					sql = { "sql-formatter" },
				},
				format_on_save = {
					lsp_fallback = true,
					async = false,
					timeout_ms = 3000,
				},
			})
			--
			vim.keymap.set({ "n", "v" }, "<leader>cf", function()
				conform.format({
					lsp_fallback = true,
					async = false,
					timeout_ms = 3000,
				})
			end, { desc = "Format file or range (in visual mode)" })
		end,
	},
}
