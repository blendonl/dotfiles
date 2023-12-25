return {
	{
		'mfussenegger/nvim-jdtls',
		ft = 'java',
		config = function()
			-- Setup Workspace
			local home = os.getenv "HOME"
			local jdtls_dir = home .. '/.local/share/nvim/mason/packages/jdtls'
			local config_dir = jdtls_dir .. 'config_linux'
			local plugins_dir = jdtls_dir .. '/plugins/'
			local path_to_jar = plugins_dir .. 'org.eclipse.equinox.launcher_1.6.600.v20231106-1826.jar'
			local path_to_lombok = '/home/notpc/.local/share/nvim/mason/packages/jdtls/lombok.jar'

			local workspace_path = "/home/notpc/Personal/"
			local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
			local workspace_dir = workspace_path .. project_name

			os.execute('mkdir -p ' .. workspace_dir)

			local config = {
				cmd = {
					"java",
					"-Declipse.application=org.eclipse.jdt.ls.core.id1",
					"-Dosgi.bundles.defaultStartLevel=4",
					"-Declipse.product=org.eclipse.jdt.ls.core.product",
					"-Dlog.protocol=true",
					"-Dlog.level=ALL",
					"-Xms1g",
					"--add-modules=ALL-SYSTEM",
					"--add-opens",
					"java.base/java.util=ALL-UNNAMED",
					"--add-opens",
					"java.base/java.lang=ALL-UNNAMED",
					"-javaagent:" .. path_to_lombok,
					"-jar",
					path_to_jar,
					"-configuration",
					config_dir,
					"-data",
					workspace_dir,
				},
				root_dir = require("jdtls.setup").find_root { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" },

				settings = {
					java = {
						eclipse = {
							downloadSources = true,
						},
						configuration = {
							updateBuildConfiguration = "interactive",
							runtimes = {
								-- {
								-- 	name = "JavaSE-21",
								-- 	path = "~/.sdkman/candidates/java/21.0.1-oracle",
								-- },
								{
									name = "JavaSE-17",
									path = "~/.sdkman/candidates/java/17.0.9-oracle/",
								},
							},
						},
						maven = {
							downloadSources = true,
						},
						implementationsCodeLens = {
							enabled = true,
						},
						referencesCodeLens = {
							enabled = true,
						},
						references = {
							includeDecompiledSources = true,
						},
						inlayHints = {
							parameterNames = {
								enabled = "all", -- literals, all, none
							},
						},
						format = {
							enabled = true,
						},
					},
					signatureHelp = { enabled = true },
					completion = {
						favoriteStaticMembers = {
							"org.hamcrest.MatcherAssert.assertThat",
							"org.hamcrest.Matchers.*",
							"org.hamcrest.CoreMatchers.*",
							"org.junit.jupiter.api.Assertions.*",
							"java.util.Objects.requireNonNull",
							"java.util.Objects.requireNonNullElse",
							"org.mockito.Mockito.*",
						},
						importOrder = {
							"java",
							"javax",
							"com",
							"org"
						},
					},
					extendedClientCapabilities = extendedClientCapabilities,
					sources = {
						organizeImports = {
							starThreshold = 9999,
							staticStarThreshold = 9999,
						},
					},
					codeGeneration = {
						toString = {
							template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
						},
						useBlocks = true,
					},
				},

				flags = {
					allow_incremental_sync = true,
				},
				init_options = {
					bundles = {},
				},
			}

			-- config['on_attach'] = function(client, bufnr)
			-- 	require 'keymaps'.map_java_keys(bufnr);
			-- 	require "lsp_signature".on_attach({
			-- 		bind = true, -- This is mandatory, otherwise border config won't get registered.
			-- 		floating_window_above_cur_line = false,
			-- 		padding = '',
			-- 		handler_opts = {
			-- 			border = "rounded"
			-- 		}
			-- 	}, bufnr)
			-- end

			-- This starts a new client & server,
			-- or attaches to an existing client & server depending on the `root_dir`.
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "java",
				callback = function()
					require('jdtls').start_or_attach(config)
				end
			})

			vim.api.nvim_create_autocmd({ "BufWritePost" }, {
				pattern = { "*.java" },
				callback = function()
					local _, _ = pcall(vim.lsp.codelens.refresh)
				end,
			})



			local status_ok, which_key = pcall(require, "which-key")
			if not status_ok then
				return
			end

			local opts = {
				mode = "n", -- NORMAL mode
				prefix = "<leader>",
				buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
				silent = true, -- use `silent` when creating keymaps
				noremap = true, -- use `noremap` when creating keymaps
				nowait = true, -- use `nowait` when creating keymaps
			}

			local vopts = {
				mode = "v", -- VISUAL mode
				prefix = "<leader>",
				buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
				silent = true, -- use `silent` when creating keymaps
				noremap = true, -- use `noremap` when creating keymaps
				nowait = true, -- use `nowait` when creating keymaps
			}

			local mappings = {
				C = {
					name = "Java",
					o = { "<Cmd>lua require'jdtls'.organize_imports()<CR>", "Organize Imports" },
					v = { "<Cmd>lua require('jdtls').extract_variable()<CR>", "Extract Variable" },
					c = { "<Cmd>lua require('jdtls').extract_constant()<CR>", "Extract Constant" },
					t = { "<Cmd>lua require'jdtls'.test_nearest_method()<CR>", "Test Method" },
					T = { "<Cmd>lua require'jdtls'.test_class()<CR>", "Test Class" },
					u = { "<Cmd>JdtUpdateConfig<CR>", "Update Config" },
				},
			}

			local vmappings = {
				C = {
					name = "Java",
					v = { "<Esc><Cmd>lua require('jdtls').extract_variable(true)<CR>", "Extract Variable" },
					c = { "<Esc><Cmd>lua require('jdtls').extract_constant(true)<CR>", "Extract Constant" },
					m = { "<Esc><Cmd>lua require('jdtls').extract_method(true)<CR>", "Extract Method" },
				},
			}

			which_key.register(mappings, opts)
			which_key.register(vmappings, vopts)
			which_key.register(vmappings, vopts)
		end
	},
}
