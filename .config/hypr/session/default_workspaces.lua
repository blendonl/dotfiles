return {
  {
    suffix = 'term',
    default = true,
    on_created_empty = function(dir, name)
      os.execute('tmux has-session -t="' ..
        name .. '" 2>/dev/null || tmux new-session -ds "' .. name .. '" -c "' .. dir .. '"')

      return 'alacritty --command tmux attach -t ' .. name
    end,
  },
  {
    suffix = 'browser',
    on_created_empty = function(_, name)
      local profile_dir = name:gsub('/', '-')
      return 'chromium --profile-directory="' .. profile_dir .. '"'
    end,
  },
  {
    suffix = 'editor',
    on_created_empty = function(dir, _)
      return 'neovide --working-directory ' .. dir
    end,
  },
}
