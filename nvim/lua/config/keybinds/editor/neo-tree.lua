local map = vim.keymap.set

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
	local git_root = vim.fn.systemlist("git -C " ..
		vim.fn.escape(current_dir, " ") .. " rev-parse --show-toplevel")[1]
	if vim.v.shell_error ~= 0 then
		return cwd
	end
	return git_root
end

map("n", "<leader>fE", function()
	require("neo-tree.command").execute({ toggle = true, dir = find_git_root() })
end, { desc = "Explorer NeoTree (root dir)" })
map("n", "<leader>fe", function()
	require("neo-tree.command").execute({ toggle = true, dir = vim.loop.cwd() })
end, { desc = "Explorer NeoTree (cwd)" })
map("n", "<leader>e", "<leader>fe", { desc = "Explorer NeoTree (root dir)", remap = true })
map("n", "<leader>E", "<leader>fE", { desc = "Explorer NeoTree (cwd)", remap = true })
map("n", "<leader>fb", function()
	require("neo-tree.command").execute({ source = "buffers", toggle = true })
end, { desc = "Buffer explorer" })
