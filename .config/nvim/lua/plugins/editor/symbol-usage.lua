return {
	{
		"Wansmer/symbol-usage.nvim",
		event = "BufReadPre", -- need run before LspAttach if you use nvim 0.9. On 0.10 use 'LspAttach'
		config = function()
			local function h(name)
				return vim.api.nvim_get_hl(0, { name = name })
			end

			-- hl-groups can have any name
			vim.api.nvim_set_hl(0, "SymbolUsageRounding", { fg = h("CursorLine").bg, italic = true })
			vim.api.nvim_set_hl(
				0,
				"SymbolUsageContent",
				{ bg = h("CursorLine").bg, fg = h("Comment").fg, italic = true }
			)
			vim.api.nvim_set_hl(0, "SymbolUsageRef", { fg = h("Function").fg, bg = h("CursorLine").bg, italic = true })
			vim.api.nvim_set_hl(0, "SymbolUsageDef", { fg = h("Type").fg, bg = h("CursorLine").bg, italic = true })
			vim.api.nvim_set_hl(0, "SymbolUsageImpl", { fg = h("@keyword").fg, bg = h("CursorLine").bg, italic = true })

			local function text_format(symbol)
				local res = {}

				local round_start = { "", "SymbolUsageRounding" }
				local round_end = { "", "SymbolUsageRounding" }

				if symbol.references then
					local usage = symbol.references <= 1 and "usage" or "usages"
					local num = symbol.references == 0 and "no" or symbol.references
					table.insert(res, round_start)
					table.insert(res, { "󰌹 ", "SymbolUsageRef" })
					table.insert(res, { ("%s %s"):format(num, usage), "SymbolUsageContent" })
					table.insert(res, round_end)
				end

				if symbol.definition then
					if #res > 0 then
						table.insert(res, { " ", "NonText" })
					end
					table.insert(res, round_start)
					table.insert(res, { "󰳽 ", "SymbolUsageDef" })
					table.insert(res, { symbol.definition .. " defs", "SymbolUsageContent" })
					table.insert(res, round_end)
				end

				if symbol.implementation then
					if #res > 0 then
						table.insert(res, { " ", "NonText" })
					end
					table.insert(res, round_start)
					table.insert(res, { "󰡱 ", "SymbolUsageImpl" })
					table.insert(res, { symbol.implementation .. " impls", "SymbolUsageContent" })
					table.insert(res, round_end)
				end

				return res
			end

			local SymbolKind = vim.lsp.protocol.SymbolKind

			require("symbol-usage").setup({
				hl = { link = "Comment" },
				filetypes = {},
				kinds = {
					SymbolKind.Function,
					SymbolKind.Method,
					SymbolKind.Class,
					SymbolKind.Interface,
					SymbolKind.Enum,
				},
				kinds_filter = {},
				vt_position = "above",
				request_pending_text = "loading...",
				references = { enabled = true, include_declaration = false },
				definition = { enabled = false },
				implementation = { enabled = false },
				disable = { lsp = {}, filetypes = {}, cond = {} },
				symbol_request_pos = "end", -- Recommended redifine only in `filetypes` override table
				text_format = text_format,
			})
		end,
	},
	-- {
	-- 	"VidocqH/lsp-lens.nvim",
	-- 	config = function()
	-- 		local SymbolKind = vim.lsp.protocol.SymbolKind
	-- 		require("lsp-lens").setup({
	-- 			enable = true,
	-- 			include_declaration = false, -- Reference include declaration
	-- 			sections = { -- Enable / Disable specific request, formatter example looks 'Format Requests'
	-- 				definition = false,
	-- 				references = true,
	-- 				implements = true,
	-- 				git_authors = true,
	-- 			},
	-- 			ignore_filetype = {
	-- 				"prisma",
	-- 			},
	-- 			-- Target Symbol Kinds to show lens information
	-- 			target_symbol_kinds = { SymbolKind.Function, SymbolKind.Method, SymbolKind.Interface },
	-- 			-- Symbol Kinds that may have target symbol kinds as children
	-- 			wrapper_symbol_kinds = { SymbolKind.Class, SymbolKind.Struct },
	-- 		})
	-- 	end,
	-- },
}
