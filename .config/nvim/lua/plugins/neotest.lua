return {

	{
		"nvim-neotest/neotest",
		dependencies = {
			"nvim-neotest/neotest-jest",
			"nvim-neotest/nvim-nio",
			"nvim-lua/plenary.nvim",
			"antoinemadec/FixCursorHold.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		keys = {
			{
				"<leader>tt",
				function()
					require("neotest").run.run()
				end,
				desc = "Run the nearest test"
			},
			{
				"<leader>tT",
				function()
					require("neotest").run.run(vim.fn.expand("%"))
				end,
				desc = "Test the current file"
			},
			{
				"<leader>td",
				function()
					require("neotest").run.run({ strategy = "dap", suite = true })
				end,
				desc = "Debug the nearest test"
			},
			{
				"<leader>tc",
				function()
					require("neotest").run.stop()
				end,
				desc = "Stop the current test"
			},
			{
				"<leader>ta",
				function()
					require("neotest").run.attach()
				end,
				desc = "Attach to the current test"
			},
			{
				"<leader>to",
				function()
					require("neotest").output.open()
				end,
				desc = "Attach to the current test"
			},

		},
		config = function()
			require(".config.nvim.lua.config.keybinds.neotest").setup({
				adapters = {
					require("neotest-jest")({
						jestCommand = "yarn test --",
						jestConfigFile = "jest.config.js",
						env = { CI = true },
						cwd = function(path)
							return vim.fn.getcwd()
						end,
					}),
				},

				benchmark = {
					enabled = true,
				},
				consumers = {},
				default_strategy = "dap",
				diagnostic = {
					enabled = true,
					severity = 1,
				},
				discovery = {
					concurrent = 0,
					enabled = true,
				},
				floating = {
					border = "rounded",
					max_height = 0.6,
					max_width = 0.6,
					options = {},
				},
				highlights = {
					adapter_name = "NeotestAdapterName",
					border = "NeotestBorder",
					dir = "NeotestDir",
					expand_marker = "NeotestExpandMarker",
					failed = "NeotestFailed",
					file = "NeotestFile",
					focused = "NeotestFocused",
					indent = "NeotestIndent",
					marked = "NeotestMarked",
					namespace = "NeotestNamespace",
					passed = "NeotestPassed",
					running = "NeotestRunning",
					select_win = "NeotestWinSelect",
					skipped = "NeotestSkipped",
					target = "NeotestTarget",
					test = "NeotestTest",
					unknown = "NeotestUnknown",
					watching = "NeotestWatching",
				},
				icons = {
					child_indent = "│",
					child_prefix = "├",
					collapsed = "─",
					expanded = "╮",
					failed = "",
					final_child_indent = " ",
					final_child_prefix = "╰",
					non_collapsible = "─",
					notify = "",
					passed = "",
					running = "",
					running_animated = { "/", "|", "\\", "-", "/", "|", "\\", "-" },
					skipped = "",
					unknown = "",
					watching = "",
				},
				jump = {
					enabled = true,
				},
				log_level = 3,
				output = {
					enabled = true,
					open_on_run = "short",
				},
				output_panel = {
					enabled = true,
					open = "botright split | resize 15",
				},
				projects = {},
				quickfix = {
					enabled = true,
					open = false,
				},
				run = {
					enabled = true,
				},
				running = {
					concurrent = true,
				},
				state = {
					enabled = true,
				},
				status = {
					enabled = true,
					signs = true,
					virtual_text = false,
				},
				strategies = {
					integrated = {
						height = 40,
						width = 120,
					},
				},
				summary = {
					animated = true,
					count = true,
					enabled = true,
					expand_errors = true,
					follow = true,
					mappings = {
						attach = "a",
						clear_marked = "M",
						clear_target = "T",
						debug = "d",
						debug_marked = "D",
						expand = { "<CR>", "<2-LeftMouse>" },
						expand_all = "e",
						help = "?",
						jumpto = "i",
						mark = "m",
						next_failed = "J",
						output = "o",
						prev_failed = "K",
						run = "r",
						run_marked = "R",
						short = "O",
						stop = "u",
						target = "t",
						watch = "w",
					},
					open = "botright vsplit | vertical resize 50",
				},
				watch = {
					enabled = true,
					symbol_queries = {
						javascript =
						'  ;query\n  ;Captures named imports\n  (import_specifier name: (identifier) @symbol)\n  ;Captures default import\n  (import_clause (identifier) @symbol)\n  ;Capture require statements\n  (variable_declarator \n  name: (identifier) @symbol\n  value: (call_expression (identifier) @function  (#eq? @function "require")))\n  ;Capture namespace imports\n  (namespace_import (identifier) @symbol)\n',
						typescript =
						'  ;query\n  ;Captures named imports\n  (import_specifier name: (identifier) @symbol)\n  ;Captures default import\n  (import_clause (identifier) @symbol)\n  ;Capture require statements\n  (variable_declarator \n  name: (identifier) @symbol\n  value: (call_expression (identifier) @function  (#eq? @function "require")))\n  ;Capture namespace imports\n  (namespace_import (identifier) @symbol)\n',
					},
				},
			})
		end,
	},
}
