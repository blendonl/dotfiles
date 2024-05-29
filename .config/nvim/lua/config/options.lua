-- This file is automatically loaded by plugins.coreoptions

-- vim.opt.spell = true
-- vim.opt.spelllang = { "en_us" }

vim.g.autoformat = true

vim.g.root_spec = { "lsp", { ".git", "lua" }, "cwd" }

local opt = vim.opt

opt.breakindent = true
opt.autowrite = true -- Enable auto write
opt.clipboard = "unnamedplus" -- Sync with system clipboard
opt.completeopt = "menu,menuone,noselect"
opt.conceallevel = 3 -- Hide * markup for bold and italic
opt.confirm = true -- Confirm to save changes before exiting modified buffer
opt.cursorline = true -- Enable highlighting of the current line
opt.expandtab = true -- Use spaces instead of tabs
opt.formatoptions = "jcroqlnt" -- tcqj
opt.grepformat = "%f:%l:%c:%m"
opt.grepprg = "rg --vimgrep"
opt.ignorecase = true -- Ignore case
opt.inccommand = "nosplit" -- preview incremental substitute
opt.laststatus = 3 -- global statusline
opt.list = true -- Show some invisible characters (tabs...
-- opt.mouse = "a"            -- Enable mouse mode
opt.number = true -- Print line number
opt.pumblend = 10 -- Popup blend
opt.pumheight = 10 -- Maximum number of entries in a popup
opt.relativenumber = true -- Relative line numbers
opt.scrolloff = 4 -- Lines of context
opt.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
opt.shiftround = true -- Round indent
opt.shiftwidth = 2 -- Size of an indent
opt.shortmess:append({ W = true, I = true, c = true, C = true })
opt.showmode = false -- Dont show mode since we have a statusline
opt.sidescrolloff = 8 -- Columns of context
opt.signcolumn = "yes" -- Always show the signcolumn, otherwise it would shift the text each time
opt.smartcase = true -- Don't ignore case with capitals
opt.smartindent = true -- Insert indents automatically
opt.spelllang = { "en" }
opt.splitbelow = true -- Put new windows below current
opt.splitkeep = "screen"
opt.splitright = true -- Put new windows right of current
opt.tabstop = 2 -- Number of spaces tabs count for
opt.termguicolors = true -- True color support
opt.timeoutlen = 300
opt.undofile = true
opt.undolevels = 10000
opt.updatetime = 200 -- Save swap file and trigger CursorHold
opt.virtualedit = "block" -- Allow cursor to move where there is no text in visual block mode
opt.wildmode = "longest:full,full" -- Command-line completion mode
opt.winminwidth = 5 -- Minimum window width
opt.wrap = false -- Disable line wrap
opt.fillchars = {
	-- foldopen = "",
	-- foldclose = "",
	-- -- fold = "⸱",
	-- fold = " ",
	-- foldsep = " ",
	diff = "╱",
	eob = " ",
}
vim.o.foldcolumn = "0" -- '0' is not bad
vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
vim.o.foldlevelstart = 99
vim.o.foldenable = true
vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]

if vim.fn.has("nvim-0.10") == 1 then
	opt.smoothscroll = true
end

-- HACK: causes freezes on <= 0.9, so only enable on >= 0.10 for now
-- if vim.fn.has("nvim-0.10") == 1 then
-- 	vim.opt.foldmethod = "expr"
-- else
-- 	vim.opt.foldmethod = "indent"
-- end

vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

-- Fix markdown indentation settings
vim.g.markdown_recommended_style = 0

-- vim.cmd("highlight Normal guibg='#202020' guifg=white")
-- vim.o.backgrounds = "dark"
vim.cmd.colorscheme("catppuccin")

vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = { "*.tsx", "*.ts", "*.jsx", "*.js" },
	command = "silent! EslintFixAll",
	group = vim.api.nvim_create_augroup("MyAutocmdsJavaScripFormatting", {}),
})

vim.o.laststatus = 0
