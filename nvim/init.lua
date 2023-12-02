-- [[ Install `lazy.nvim` plugin manager ]]
--    `:help lazy.nvim.txt` for more info
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	-- { import = "plugins.ui" },
	{ import = "plugins" },
})

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank()
	end,
	group = highlight_group,
	pattern = "*",
})

-- Telescope live_grep in git root
-- Function to find the git root directory based on the current buffer's path
-- local function find_git_root()
--   -- Use the current buffer's path as the starting point for the git search
--   local current_file = vim.api.nvim_buf_get_name(0)
--   local current_dir
--   local cwd = vim.fn.getcwd()
--   -- If the buffer is not associated with a file, return nil
--   if current_file == "" then
--     current_dir = cwd
--   else
--     -- Extract the directory from the current file's path
--     current_dir = vim.fn.fnamemodify(current_file, ":h")
--   end
--
--   -- Find the Git root directory from the current file's path
--   local git_root = vim.fn.systemlist("git -C " .. vim.fn.escape(current_dir, " ") .. " rev-parse --show-toplevel")[1]
--   if vim.v.shell_error ~= 0 then
--     print("Not a git repository. Searching on current working directory")
--     return cwd
--   end
--   return git_root
-- end

-- Custom live_grep function to search in git root
-- local function live_grep_git_root()
--   local git_root = find_git_root()
--   if git_root then
--     require('telescope.builtin').live_grep({
--       search_dirs = { git_root },
--     })
--   end
-- end

-- vim.api.nvim_create_user_command('LiveGrepGitRoot', live_grep_git_root, {})
--
-- -- [[ Configure LSP ]]
-- --  This function gets run when an LSP connects to a particular buffer.
-- local on_attach = function(_, bufnr)
--   -- NOTE: Remember that lua is a real programming language, and as such it is possible
--   -- to define small helper and utility functions so you don't have to repeat yourself
--   -- many times.
--   --
--   -- In this case, we create a function that lets us more easily define mappings specific
--   -- for LSP related items. It sets the mode, buffer and description for us each time.
--   -- Create a command `:Format` local to the LSP buffer
--   vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
--     vim.lsp.buf.format()
--   end, { desc = 'Format current buffer with LSP' })
-- end

-- document existing key chains

require("config.options")
require("config.keybinds")
