return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"j-hui/fidget.nvim",
			"folke/neodev.nvim",
		},
		config = function()
			-- require("lspconfig").eslintd.setup({
			-- 	on_attach = function(client, bufnr)
			-- 		require("workspace-diagnostics").populate_workspace_diagnostics(client, bufnr)
			-- 	end,
			-- })

			local capabilities = require("blink.cmp").get_lsp_capabilities()
			local lspconfig = require("lspconfig")

			lspconfig.graphql.setup({
				capabilities = capabilities,
				cmd = { "graphql-lsp", "server", "-m", "stream" },
				filetypes = { "graphql" },
				root_dir = function(startpath)
					return "/home/notpc/work/pump/pump-api/resources/graphql/typeDefs/"
				end,
			})

			lspconfig["vtsls"].setup({ capabilities = capabilities })
			lspconfig["lua_ls"].setup({
				capabilities = capabilities,
			})
			lspconfig.html.setup({
				capabilities = capabilities,
			})
			lspconfig.harper_ls.setup({
				settings = {
					["harper-ls"] = {
						userDictPath = "",
						fileDictPath = "",
						linters = {
							SpellCheck = true,
							SpelledNumbers = false,
							AnA = true,
							SentenceCapitalization = true,
							UnclosedQuotes = true,
							WrongQuotes = false,
							LongSentences = true,
							RepeatedWords = true,
							Spaces = true,
							Matcher = true,
							CorrectNumberSuffix = true,
						},
						codeActions = {
							ForceStable = false,
						},
						markdown = {
							IgnoreLinkTitle = false,
						},
						diagnosticSeverity = "hint",
						isolateEnglish = false,
						dialect = "American",
					},
				},
			})
			lspconfig.cssls.setup({
				capabilities = capabilities,
			})
		end,
	},
}
