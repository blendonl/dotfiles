-- return {
-- 	{
-- 		"nvim-neo-tree/neo-tree.nvim",
-- 		branch = "v3.x",
-- 		deactivate = function()
-- 			vim.cmd([[Neotree close]])
-- 		end,
-- 		cmd = "Neotree",
-- 		init = function()
-- 			if vim.fn.argc(-1) == 1 then
-- 				local stat = vim.loop.fs_stat(vim.fn.argv(0))
-- 				if stat and stat.type == "directory" then
-- 					require("neo-tree")
-- 				end
-- 			end
-- 		end,
-- 		opts = {
-- 			sources = { "filesystem", "buffers", "git_status", "document_symbols" },
-- 			open_files_do_not_replace_types = { "terminal", "Trouble", "trouble", "qf", "Outline" },
-- 			filesystem = {
-- 				bind_to_cwd = false,
-- 				follow_current_file = { enabled = true },
-- 				use_libuv_file_watcher = true,
-- 			},
-- 			window = {
-- 				mappings = {
-- 					["<space>"] = "none",
-- 				},
-- 			},
-- 			default_component_configs = {
-- 				indent = {
-- 					with_expanders = true, -- if nil and file nesting is enabled, will enable expanders
-- 					expander_collapsed = "",
-- 					expander_expanded = "",
-- 					expander_highlight = "NeoTreeExpander",
-- 				},
-- 			},
-- 		},
-- 		config = function(_, opts)
-- 			-- If you want icons for diagnostic errors, you'll need to define them somewhere:
-- 			vim.fn.sign_define("DiagnosticSignError", { text = " ", texthl = "DiagnosticSignError" })
-- 			vim.fn.sign_define("DiagnosticSignWarn", { text = " ", texthl = "DiagnosticSignWarn" })
-- 			vim.fn.sign_define("DiagnosticSignInfo", { text = " ", texthl = "DiagnosticSignInfo" })
-- 			vim.fn.sign_define("DiagnosticSignHint", { text = "󰌵", texthl = "DiagnosticSignHint" })
--
-- 			opts.event_handlers = {
--
-- 				{
-- 					event = "file_opened",
-- 					handler = function(file_path)
-- 						-- auto close
-- 						-- vimc.cmd("Neotree close")
-- 						-- OR
-- 						require("neo-tree.command").execute({ action = "close" })
-- 					end,
-- 				},
-- 			}
-- 			require("neo-tree").setup(opts)
-- 			vim.api.nvim_create_autocmd("TermClose", {
-- 				pattern = "*lazygit",
-- 				callback = function()
-- 					if package.loaded["neo-tree.sources.git_status"] then
-- 						require("neo-tree.sources.git_status").refresh()
-- 					end
-- 				end,
-- 			})
-- 		end,
-- 	},
-- }
--#region
return {
	"nvim-tree/nvim-tree.lua",
	version = "*",
	lazy = false,
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		require("nvim-tree").setup({
			update_focused_file = {
				enable = true,
			},
			diagnostics = {
				enable = true,
				show_on_dirs = true,
				show_on_open_dirs = false,
				severity = { min = vim.diagnostic.severity.WARNING, max = vim.diagnostic.severity.ERROR },
				icons = {
					hint = "",
					info = "",
					warning = "",
					error = "",
				},
			},
			view = {
				width = 40,
				side = "left",
				signcolumn = "yes",
			},

			log = {
				enable = true,
				truncate = true,
				types = {
					diagnostics = true,
				},
			},
		})
	end,
}
