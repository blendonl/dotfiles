local map = vim.keymap.set
local spectre = require('spectre')

map('n', '<leader>rs', function() spectre.open() end, { desc = "Replace in files (Spectre)" })
