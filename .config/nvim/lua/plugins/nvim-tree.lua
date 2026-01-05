return {
	"nvim-tree/nvim-tree.lua",
	version = "*",
	lazy = false,
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	keybindings = {
		{
			"<leader>fE",
			function()
				local function find_git_root() -- Use the current buffer's path as the starting point for the git search
					local current_file = vim.api.nvim_buf_get_name(0)
					local current_dir
					local cwd = vim.fn.getcwd()
					-- If the buffer is not associated with a file, return nil
					if current_file == "" then
						current_dir = cwd
					else
						-- Extract the directory from the current file's path
						current_dir = vim.fn.fnamemodify(current_file, ":h")
					end

					-- Find the Git root directory from the current file's path
					local git_root = vim.fn.systemlist("git -C " .. vim.fn.escape(current_dir, " ") .. " rev-parse --show-toplevel")
							[1]
					if vim.v.shell_error ~= 0 then
						return cwd
					end
					return git_root
				end


				require("nvim-tree-api").tree.toggle({ path = find_git_root(), update_focused_file = true })
			end,
			desc = "Explorer Fyler (root dir)"
		},

		{
			"<leader>fe",
			function()
				require("nvim-tree-api").tree.toggle({ update_focused_file = true })
			end,
			desc = "Explorer Fyler (cwd)"
		},

	},
	config = function()
		require("nvim-tree").setup({
			actions = {
				open_file = {
					quit_on_open = true,
				},
			},
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

				float = {

					enable = false,
					open_win_config = {
						relative = "editor",
						border = "rounded",
						width = 100,
						height = 100,
						row = 20,
						col = 30,
					},

				},
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
