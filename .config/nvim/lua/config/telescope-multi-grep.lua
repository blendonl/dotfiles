local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local conf = require("telescope.config").values

local M = {}

local live_grep_with = function(opts)
	opts = opts or {}
	opts.cwd = opts.cwd or vim.uv.cwd()

	local finder = finders.new_async_job({
		command_generator = function(prompt)
			if not prompt or prompt == "" then
				return nil
			end

			local piceses = vim.split(prompt, "  ")
			local args = { "rg" }

			if piceses[1] then
				table.insert(args, "-e")
				table.insert(args, piceses[1])
			end

			if piceses[2] then
				table.insert(args, "-g")
				table.insert(args, piceses[2])
			end

			return vim.tbl_flatten({
				args,
				{ "--color=never", "--no-heading", "--with-filename", "--line-number", "--column", "--smart-case" },
			})
		end,
		entry_maker = make_entry.gen_from_vimgrep(opts),
		cwd = opts.cwd,
	})

	pickers
		.new(opts, {
			debounce = 100,
			finder = finder,
			prompt_title = "Multi Grep 1",
			previewer = conf.grep_previewer(opts),
			sorter = require("telescope.sorters").empty(),
		})
		:find()
end

M.setup = function()
	vim.keymap.set("n", "<leader>sG", function()
		live_grep_with()
	end, { desc = "[S]earch by [G]rep on Git Root" })
end

return M
