return {
	{
		'neovim/nvim-lspconfig',
		dependencies = {
			{ 'j-hui/fidget.nvim', opts = {} },
			{ 'folke/neodev.nvim', config = function() end }
		},
		config = function()
		end
	},
}
