return {
	{
		'neovim/nvim-lspconfig',
		dependencies = {
			'j-hui/fidget.nvim',
			'folke/neodev.nvim'
		},
		config = function()
			require 'lspconfig'.lua_ls.setup({
				settings = {
					Lua = {
						diagnostics = {
							globals = { 'vim' },
						},
					},
				}
			})
		end
	},
}
