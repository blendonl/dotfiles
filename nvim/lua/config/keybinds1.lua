local Util = require("lazyvim.util")

local map = vim.keymap.set

-- Remap for dealing with word wrap
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Move to window using the <ctrl> hjkl keys
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window", remap = true })

-- Resize window using <ctrl> arrow keys
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

-- Move Lines
map("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move down" })
map("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move up" })
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move down" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move up" })
map("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move down" })
map("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move up" })

-- buffers
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })

-- Clear search with <esc>
map({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and clear hlsearch" })

-- Clear search, diff update and redraw
-- taken from runtime/lua/_editor.lua
map(
	"n",
	"<leader>ur",
	"<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>",
	{ desc = "Redraw / clear hlsearch / diff update" }
)

-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next search result" })
map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next search result" })
map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next search result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev search result" })
map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev search result" })
map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev search result" })

-- Add undo break-points
map("i", ",", ",<c-g>u")
map("i", ".", ".<c-g>u")
map("i", ";", ";<c-g>u")

-- save file
--map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })

--keywordprg
map("n", "<leader>K", "<cmd>norm! K<cr>", { desc = "Keywordprg" })

-- better indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- lazy
map("n", "<leader>l", "<cmd>Lazy<cr>", { desc = "Lazy" })

-- new file
map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })

map("n", "<leader>xl", "<cmd>lopen<cr>", { desc = "Location List" })
map("n", "<leader>xq", "<cmd>copen<cr>", { desc = "Quickfix List" })

map("n", "[q", vim.cmd.cprev, { desc = "Previous quickfix" })
map("n", "]q", vim.cmd.cnext, { desc = "Next quickfix" })

-- formatting
map({ "n", "v" }, "<leader>cf", function()
	Util.format({ force = true })
end, { desc = "Format" })

-- diagnostic
local diagnostic_goto = function(next, severity)
	local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
	severity = severity and vim.diagnostic.severity[severity] or nil
	return function()
		go({ severity = severity })
	end
end
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
map("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
map("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
map("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
map("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
map("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
map("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })

-- stylua: ignore start

-- toggle options
map("n", "<leader>uf", function() Util.format.toggle() end, { desc = "Toggle auto format (global)" })
map("n", "<leader>uF", function() Util.format.toggle(true) end, { desc = "Toggle auto format (buffer)" })
map("n", "<leader>us", function() Util.toggle("spell") end, { desc = "Toggle Spelling" })
map("n", "<leader>uw", function() Util.toggle("wrap") end, { desc = "Toggle Word Wrap" })
map("n", "<leader>uL", function() Util.toggle("relativenumber") end, { desc = "Toggle Relative Line Numbers" })
map("n", "<leader>ul", function() Util.toggle.number() end, { desc = "Toggle Line Numbers" })
map("n", "<leader>ud", function() Util.toggle.diagnostics() end, { desc = "Toggle Diagnostics" })
local conceallevel = vim.o.conceallevel > 0 and vim.o.conceallevel or 3
map("n", "<leader>uc", function() Util.toggle("conceallevel", false, { 0, conceallevel }) end,
  { desc = "Toggle Conceal" })
if vim.lsp.inlay_hint then
  map("n", "<leader>uh", function() vim.lsp.inlay_hint(0, nil) end, { desc = "Toggle Inlay Hints" })
end
map("n", "<leader>uT", function() if vim.b.ts_highlight then vim.treesitter.stop() else vim.treesitter.start() end end,
  { desc = "Toggle Treesitter Highlight" })

-- lazygit
map("n", "<leader>gg",
  function() Util.terminal({ "lazygit" }, { cwd = Util.root(), esc_esc = false, ctrl_hjkl = false }) end,
  { desc = "Lazygit (root dir)" })
map("n", "<leader>gG", function() Util.terminal({ "lazygit" }, { esc_esc = false, ctrl_hjkl = false }) end,
  { desc = "Lazygit (cwd)" })

-- quit
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit all" })

-- highlights under cursor
map("n", "<leader>ui", vim.show_pos, { desc = "Inspect Pos" })

-- LazyVim Changelog
-- map("n", "<leader>L", function() Util.news.changelog() end, { desc = "LazyVim Changelog" })

-- floating terminal
local lazyterm = function() Util.terminal(nil, { cwd = Util.root() }) end
map("n", "<leader>ft", lazyterm, { desc = "Terminal (root dir)" })
map("n", "<leader>fT", function() Util.terminal() end, { desc = "Terminal (cwd)" })
map("n", "<c-/>", lazyterm, { desc = "Terminal (root dir)" })
map("n", "<c-_>", lazyterm, { desc = "which_key_ignore" })

-- Terminal Mappings
map("t", "<esc><esc>", "<c-\\><c-n>", { desc = "Enter Normal Mode" })
map("t", "<C-h>", "<cmd>wincmd h<cr>", { desc = "Go to left window" })
map("t", "<C-j>", "<cmd>wincmd j<cr>", { desc = "Go to lower window" })
map("t", "<C-k>", "<cmd>wincmd k<cr>", { desc = "Go to upper window" })
map("t", "<C-l>", "<cmd>wincmd l<cr>", { desc = "Go to right window" })
map("t", "<C-/>", "<cmd>close<cr>", { desc = "Hide Terminal" })
map("t", "<c-_>", "<cmd>close<cr>", { desc = "which_key_ignore" })

-- windows
map("n", "<leader>ww", "<C-W>p", { desc = "Other window", remap = true })
map("n", "<leader>wd", "<C-W>c", { desc = "Delete window", remap = true })
map("n", "<leader>w-", "<C-W>s", { desc = "Split window below", remap = true })
map("n", "<leader>w|", "<C-W>v", { desc = "Split window right", remap = true })
map("n", "<leader>-", "<C-W>s", { desc = "Split window below", remap = true })
map("n", "<leader>|", "<C-W>v", { desc = "Split window right", remap = true })

-- tabs
map("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last Tab" })
map("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First Tab" })
map("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New Tab" })
map("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next Tab" })
map("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
map("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })


map('n', '<leader>rn', vim.lsp.buf.rename, { desc = 'Rename' })
map('n', '<leader>ca', vim.lsp.buf.code_action, { desc = 'Code Action' })


require('which-key').register {
  ['<leader>w'] = { name = ' Windows', _ = 'which_key_ignore' },
  ['<leader>r'] = { name = ' Rename' },
  ['<leader>c'] = { name = ' Code' },
  ['<leader>s'] = { name = ' Search' },
  ['<leader>b'] = { name = ' Buffers' },
  ['<leader>d'] = { name = ' Document' },
  ['<leader>f'] = { name = ' File' },
  ['<leader>g'] = { name = ' Git' },
  ['<leader>q'] = { name = ' Session' },
  ['<leader>u'] = { name = ' Options' },
  ['<leader>x'] = { name = ' List' },
  ['<leader><Tab>'] = { name = ' Tabs' },



  --   ['<leader>h'] = { name = 'More git', _ = 'which_key_ignore' },
  --   ['<leader>r'] = { name = '[R]ename', _ = 'which_key_ignore' },
  --   ['<leader>s'] = { name = '[S]earch', _ = 'which_key_ignore' },
  --   ['<leader>w'] = { name = '[W]orkspace', _ = 'which_key_ignore' },
}

map('n',
  "<leader>fe",
  function()
    require("neo-tree.command").execute({ toggle = true, dir = require('lazyvim.util').root() })
  end,
  { desc = "Explorer NeoTree (root dir)" })
map('n',
  "<leader>fE",
  function()
    require("neo-tree.command").execute({ toggle = true, dir = vim.loop.cwd() })
  end,
  { desc = "Explorer NeoTree (cwd)" })
map('n', "<leader>e", "<leader>fe", { desc = "Explorer NeoTree (root dir)", remap = true })
map('n', "<leader>E", "<leader>fE", { desc = "Explorer NeoTree (cwd)", remap = true })
map('n',
  "<leader>ge",
  function()
    require("neo-tree.command").execute({ source = "git_status", toggle = true })
  end,
  { desc = "Git explorer" })
map('n',
  "<leader>be",
  function()
    require("neo-tree.command").execute({ source = "buffers", toggle = true })
  end,
  { desc = "Buffer explorer" })



map('n', "<leader>,", "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>", { desc = "Switch Buffer" })
map('n', "<leader>/", Util.telescope("live_grep"), { desc = "Grep (root dir)" })
map('n', "<leader>:", "<cmd>Telescope command_history<cr>", { desc = "Command History" })
map('n', "<leader>m", "<cmd>Telescope harpoon marks<cr>", { desc = "Command History" })
map('n', "<leader><space>", Util.telescope("files"), { desc = "Find Files (root dir)" })
map('n', "<leader>fb", "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>", { desc = "Buffers" })
map('n', "<leader>fc", Util.telescope.config_files(), { desc = "Find Config File" })
map('n', "<leader>ff", Util.telescope("files"), { desc = "Find Files (root dir)" })
map('n', "<leader>fF", Util.telescope("files", { cwd = false }), { desc = "Find Files (cwd)" })
map('n', "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Recent" })
map('n', "<leader>fR", Util.telescope("oldfiles", { cwd = vim.loop.cwd() }), { desc = "Recent (cwd)" })
map('n', "<leader>gc", "<cmd>Telescope git_commits<CR>", { desc = "commits" })
map('n', "<leader>gs", "<cmd>Telescope git_status<CR>", { desc = "status" })
map('n', '<leader>s"', "<cmd>Telescope registers<cr>", { desc = "Registers" })
map('n', "<leader>sa", "<cmd>Telescope autocommands<cr>", { desc = "Auto Commands" })
map('n', "<leader>sb", "<cmd>Telescope current_buffer_fuzzy_find<cr>", { desc = "Buffer" })
map('n', "<leader>sc", "<cmd>Telescope command_history<cr>", { desc = "Command History" })
map('n', "<leader>sC", "<cmd>Telescope commands<cr>", { desc = "Commands" })
map('n', "<leader>sd", "<cmd>Telescope diagnostics bufnr=0<cr>", { desc = "Document diagnostics" })
map('n', "<leader>sD", "<cmd>Telescope diagnostics<cr>", { desc = "Workspace diagnostics" })
map('n', "<leader>sg", Util.telescope("live_grep"), { desc = "Grep (root dir)" })
map('n', "<leader>sG", Util.telescope("live_grep", { cwd = false }), { desc = "Grep (cwd)" })
map('n', "<leader>sh", "<cmd>Telescope help_tags<cr>", { desc = "Help Pages" })
map('n', "<leader>sH", "<cmd>Telescope highlights<cr>", { desc = "Search Highlight Groups" })
map('n', "<leader>sk", "<cmd>Telescope keymaps<cr>", { desc = "Key Maps" })
map('n', "<leader>sM", "<cmd>Telescope man_pages<cr>", { desc = "Man Pages" })
map('n', "<leader>sm", "<cmd>Telescope marks<cr>", { desc = "Jump to Mark" })
map('n', "<leader>so", "<cmd>Telescope vim_options<cr>", { desc = "Options" })
map('n', "<leader>sR", "<cmd>Telescope resume<cr>", { desc = "Resume" })
map('n', "<leader>sw", Util.telescope("grep_string", { word_match = "-w" }), { desc = "Word (root dir)" })
map('n', "<leader>sW", Util.telescope("grep_string", { cwd = false, word_match = "-w" }), { desc = "Word (cwd)" })
map('v', "<leader>sw", Util.telescope("grep_string"), { desc = "Selection (root dir)" })
map('v', "<leader>sW", Util.telescope("grep_string", { cwd = false }), { desc = "Selection (cwd)" })
map('n', "<leader>uC", Util.telescope("colorscheme", { enable_preview = true }), { desc = "Colorscheme with preview" })
map('n', "<leader>ss",
  function()
    require("telescope.builtin").lsp_document_symbols({
      symbols = require("lazyvim.config").get_kind_filter(),
    })
  end,
  { desc = "Goto Symbol" })
map('n', "<leader>sS",
  function()
    require("telescope.builtin").lsp_dynamic_workspace_symbols({
      symbols = require("lazyvim.config").get_kind_filter(),
    })
  end,
  { desc = "Goto Symbol (Workspace)" })



map("n", "j", "jzz")
map("n", "k", "kzz")
map("n", "G", "Gzz")

map('n', '<leader>hm', function()
require("harpoon.mark").add_file()
end, {desc = "mark file"} )

map('n', '<leader>hh', function()
require("harpoon.ui").toggle_quick_menu()
end, {desc = "mark file"} )

map('n', '<leader>bd', function(n)
require("mini.bufremove").delete(n, false)
end, {desc = "mark file"} )
