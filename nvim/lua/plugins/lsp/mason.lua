return {
	{

		"williamboman/mason.nvim",
		cmd = "Mason",
		build = ":MasonUpdate",
		opts = {
		},
	},

	{
		'williamboman/mason-lspconfig.nvim',
		config = function()
			local servers = {

				lua_ls = {
					Lua = {
						workspace = { checkThirdParty = false },
						telemetry = { enable = false },
					},
				},
			}
			local mason_lspconfig = require 'mason-lspconfig'
			mason_lspconfig.setup_handlers {
				function(server_name)
					if server_name ~= 'jdtls' then
						require('lspconfig')[server_name].setup {
							capabilities = capabilities,
							on_attach = on_attach,
							settings = servers[server_name],
							filetypes = (servers[server_name] or {}).filetypes,
						}
					end
				end,
			}
		end
	},
}
