local capabilities = require("blink.cmp").get_lsp_capabilities()
local lspconfig = vim.lsp.config("*", {
	capabilities = capabilities,
})

vim.lsp.enable("vtsls")
vim.lsp.enable("cssls")
vim.lsp.enable("html")
vim.lsp.enable("jsonls")
vim.lsp.enable("lua_ls")
