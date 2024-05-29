-- see if the file exists
function file_exists(file)
	local f = io.open(file, "rb")
	if f then f:close() end
	return f ~= nil
end

-- get all lines from a file, returns an empty
-- list/table if the file does not exist
function lines_from(file)
	if not file_exists(file) then return {} end
	local lines = {}
	for line in io.lines(file) do
		line = string.gsub(line, "%s+", "")
		line = string.sub(line, 4)
		local index = string.find(line, '=', 1, true)


		if index == nil then
			lines[#lines + 1] = line
		else
			if index ~= nil then
				local lineName = string.sub(line, 0, index - 1)
				lines[lineName] = string.sub(line, index + 2, #line - 1)
			end
		end
	end
	return lines
end

return {
	-- {
	-- 	'jesseleite/nvim-noirbuddy',
	-- 	dependencies = {
	-- 		{ 'tjdevries/colorbuddy.nvim', branch = 'dev' }
	-- 	},
	-- 	lazy = true,
	-- 	opts = {
	-- 	},
	-- 	config = function()
	-- 		local file = '/home/notpc/.cache/wal/colors-wal.vim'
	-- 		local lines = lines_from(file)
	--
	-- 		require('noirbuddy').setup({
	-- 			colors = {
	-- 				primary = lines['color11'],
	-- 				secondary = '#f5f5f5',
	-- 				background = '#000000',
	-- 				noir_0 = lines['color6'], -- `noir_0` is light for dark themes, and dark for light themes
	-- 				noir_1 = '#f5f5f5',
	-- 				noir_2 = '#d5d5d5',
	-- 				noir_3 = '#b4b4b4',
	-- 				noir_4 = '#a7a7a7',
	-- 				noir_5 = '#949494',
	-- 				noir_6 = '#737373',
	-- 				noir_7 = '#535353',
	-- 				noir_8 = '#323232',
	-- 				noir_9 = '#212121', -- `noir_9` is dark for dark themes, and light for light themes
	-- 				diagnostic_error = lines['color5'],
	-- 				diagnostic_warning = lines['color3'],
	-- 				diagnostic_info = '#d5d5d5',
	-- 				diagnostic_hint = '#b4b4b4',
	-- 				diff_add = '#f5f5f5',
	-- 				diff_change = '#737373',
	-- 				diff_delete = '#EC0034',
	-- 			},
	-- 			styles = {
	-- 				italic = true,
	-- 				bold = true,
	-- 				underline = false,
	-- 				undercurl = true,
	-- 			},
	-- 		})
	--
	-- 		-- require('noirbuddy').setup({
	-- 		-- 	colors = {
	-- 		-- 		primary = lines['foreground'],
	-- 		-- 		secondary = lines['cursor'],
	-- 		-- 		background = lines['color0'],
	-- 		-- 		noir_0 = lines['color1'], -- `noir_0` is light for dark themes, and dark for light themes
	-- 		-- 		noir_1 = lines['color2'],
	-- 		-- 		noir_2 = lines['color3'],
	-- 		-- 		noir_3 = lines['color4'],
	-- 		-- 		noir_4 = lines['color5'],
	-- 		-- 		noir_5 = lines['color6'],
	-- 		-- 		noir_6 = lines['color7'],
	-- 		-- 		noir_7 = lines['color8'],
	-- 		-- 		noir_8 = lines['color9'],
	-- 		-- 		noir_9 = lines['color10'], -- `noir_9` is dark for dark themes, and light for light themes
	-- 		-- 		diagnostic_error = lines['color5'],
	-- 		-- 		diagnostic_warning = lines['color3'],
	-- 		-- 		diagnostic_info = '#d5d5d5',
	-- 		-- 		diagnostic_hint = '#b4b4b4',
	-- 		-- 		diff_add = '#f5f5f5',
	-- 		-- 		diff_change = '#737373',
	-- 		-- 		diff_delete = '#EC0034',
	-- 		-- 	},
	-- 		-- 	styles = {
	-- 		-- 		italic = true,
	-- 		-- 		bold = true,
	-- 		-- 		underline = false,
	-- 		-- 		undercurl = true,
	-- 		-- 	},
	-- 		-- })
	-- 	end
	--
	-- }
}
