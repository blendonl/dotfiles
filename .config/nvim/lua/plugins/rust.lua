return {
  {
    'mrcjkb/rustaceanvim',
    version = '^5', -- Recommended
    lazy = false,   -- This plugin is already lazy
    config = function()
      vim.g.rustaceanvim = {
        -- Plugin configuration
        tools = {},
        -- LSP configuration
        server = {
          on_attach = function(client, bufnr)
            -- You can set custom keymaps here
            vim.keymap.set("n", "<leader>ca", function() vim.cmd.RustLsp('codeAction') end,
              { desc = "Rust Code Action", buffer = bufnr })
          end,
          default_settings = {
            -- rust-analyzer language server configuration
            ['rust-analyzer'] = {
              cargo = {
                allFeatures = true,
                loadOutDirsFromCheck = true,
                buildScripts = {
                  enable = true,
                },
              },
              -- Add clippy lints for diagnostics
              checkOnSave = {
                command = "clippy",
              },
            },
          },
        },
      }
    end
  }
}
