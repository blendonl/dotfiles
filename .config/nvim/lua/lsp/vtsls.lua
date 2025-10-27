local capabilities = require("blink.cmp").get_lsp_capabilities()
local lspconfig = vim.lsp.config()

lspconfig.enable("vtsls")

lspconfig["vtsls"].setup({ capabilities = capabilities })
