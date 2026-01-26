return {
	-- {
	-- 	"yetone/avante.nvim",
	-- 	event = "VeryLazy",
	-- 	lazy = false,
	-- 	version = false, -- set this to "*" if you want to always pull the latest change, false to update on release
	-- 	opts = {
	-- 		-- add any opts here
	-- 		provider = "copilot",
	-- 	},
	-- 	-- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
	-- 	build = "make",
	-- 	-- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
	-- 	dependencies = {
	-- 		"stevearc/dressing.nvim",
	-- 		"nvim-lua/plenary.nvim",
	-- 		"MunifTanjim/nui.nvim",
	-- 		--- The below dependencies are optional,
	-- 		"hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
	-- 		"nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
	-- 		"zbirenbaum/copilot.lua", -- for providers='copilot'
	-- 		{
	-- 			-- support for image pasting
	-- 			"HakonHarnes/img-clip.nvim",
	-- 			event = "VeryLazy",
	-- 			opts = {
	-- 				-- recommended settings
	-- 				default = {
	-- 					embed_image_as_base64 = false,
	-- 					prompt_for_file_name = false,
	-- 					drag_and_drop = {
	-- 						insert_mode = true,
	-- 					},
	-- 					-- required for Windows users
	-- 					use_absolute_path = true,
	-- 				},
	-- 			},
	-- 		},
	-- 		{
	-- 			-- Make sure to set this up properly if you have lazy=true
	-- 			"MeanderingProgrammer/render-markdown.nvim",
	-- 			opts = {
	-- 				file_types = { "markdown", "Avante" },
	-- 			},
	-- 			ft = { "markdown", "Avante" },
	-- 		},
	-- 	},
	-- },
	-- -- {
	-- -- 	"zbirenbaum/copilot.vim",
	-- -- 	config = function()
	-- -- 		require("copilot").setup({
	-- -- 			suggestion = { enabled = false },
	-- -- 			panel = { enabled = false },
	-- -- 		})
	-- -- 	end,
	-- -- },
	-- {
	-- 	"olimorris/codecompanion.nvim",
	-- 	dependencies = {
	-- 		"nvim-lua/plenary.nvim",
	-- 		"nvim-treesitter/nvim-treesitter",
	-- 	},
	-- 	config = function()
	-- 		require("codecompanion").setup({
	-- 			-- your config goes here
	-- 			-- or leave it empty to use the default settings
	-- 			-- refer to the configuration section below
	-- 			adapters = {
	-- 				ollama = function()
	-- 					return require("codecompanion.adapters").extend("ollama", {
	-- 						name = "deepseek-coder-v2", -- Give this adapter a different name to differentiate it from the default ollama adapter
	-- 						env = {
	-- 							url = "http://192.168.1.49:11434", -- URL of the Ollama server_capabilities
	-- 						},
	-- 						schema = {
	-- 							model = {
	-- 								default = "deepseek-coder-v2",
	-- 							},
	-- 							num_ctx = {
	-- 								default = 16384,
	-- 							},
	-- 							num_predict = {
	-- 								default = -1,
	-- 							},
	-- 						},
	-- 					})
	-- 				end,
	-- 			},
	-- 			display = {
	-- 				chat = {
	-- 					show_settings = true,
	-- 				},
	-- 			},
	--
	-- 			strategies = {
	-- 				-- CHAT STRATEGY ----------------------------------------------------------
	-- 				chat = {
	-- 					adapter = "ollama",
	-- 				},
	-- 				-- INLINE STRATEGY --------------------------------------------------------
	-- 				inline = {
	-- 					adapter = "ollama",
	-- 				},
	-- 			},
	-- 		})
	-- 	end,
	-- },
	-- {
	-- 	"milanglacier/minuet-ai.nvim",
	-- 	dependencies = {
	-- 		"nvim-lua/plenary.nvim",
	-- 		"Saghen/blink.cmp",
	-- 	},
	-- 	config = function()
	-- 		require("minuet").setup({
	-- 			provider = "openai_fim_compatible",
	-- 			provider_options = {
	-- 				openai_fim_compatible = {
	-- 					api_key = "TERM",
	-- 					name = "Ollama",
	-- 					end_point = "http://192.168.1.49:11434/v1/completions",
	-- 					model = "deepseek-coder-v2",
	-- 					optional = {
	-- 						max_tokens = 256,
	-- 						top_p = 0.9,
	-- 					},
	-- 				},
	-- 			},
	-- 		})
	-- 	end,
	-- },
	-- {
	-- 	"giuxtaposition/blink-cmp-copilot",
	-- },

	{ "github/copilot.vim", opts = {}, config = function() end },

	-- {
	-- 	"coder/claudecode.nvim",
	-- 	dependencies = { "folke/snacks.nvim" },
	-- 	config = true,
	-- 	keys = {
	-- 		{ "<leader>a", nil, desc = "AI/Claude Code" },
	-- 		{ "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
	-- 		{ "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
	-- 		{ "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
	-- 		{ "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
	-- 		{ "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
	-- 		{ "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
	-- 		{ "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
	-- 		{
	-- 			"<leader>ah",
	-- 			"<cmd>ClaudeCodeHttpGenerate<cr>",
	-- 			mode = "v",
	-- 			desc = "Send to Claude Http",
	-- 		},
	-- 		{
	-- 			"<leader>as",
	-- 			"<cmd>ClaudeCodeTreeAdd<cr>",
	-- 			desc = "Add file",
	-- 			ft = { "NvimTree", "neo-tree", "oil", "minifiles" },
	-- 		},
	-- 		-- Diff management
	-- 		{ "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
	-- 		{ "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
	-- 	},
	{
		"carlos-algms/agentic.nvim",

		opts = {
			-- Available by default: "claude-acp" | "gemini-acp" | "codex-acp" | "opencode-acp" | "cursor-acp" | "auggie-acp"
			provider = "opencode-acp", -- setting the name here is all you need to get started
		},

		-- these are just suggested keymaps; customize as desired
		keys = {
			{
				"<leader>aa",
				function()
					require("agentic").toggle()
				end,
				mode = { "n", "v", "i" },
				desc = "Toggle Agentic Chat",
			},
			{
				"<leader>av",
				function()
					require("agentic").add_selection_or_file_to_context()
				end,
				mode = { "n", "v" },
				desc = "Add file or selection to Agentic to Context",
			},
			{
				"<leader>an",
				function()
					require("agentic").new_session()
				end,
				mode = { "n", "v" },
				desc = "New Agentic Session",
			},
			{
				"<leader>as",
				function()
					require("agentic").stop_generation()
				end,
				mode = { "n", "v" },
				desc = "Stop Selection to Agentic",
			},
		},
	},
}
