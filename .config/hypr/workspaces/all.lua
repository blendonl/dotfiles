local r = require('workspaces.registry')

r.rule({
  workspace        = 'terminal',
  default_name     = 'terminal',
  default          = true,
  on_created_empty = 'alacritty',
})

r.rule({
  workspace        = 'special:notes',
  gaps_out         = 100,
  on_created_empty = 'alacritty --command=nvim --working-directory=/mnt/data/notes',
})

r.rule({
  workspace        = 'name:quran',
  default          = false,
  on_created_empty = 'chromium --app=https://bayyinahtv.com/ --profile-directory="Profile 1"',
})

-- Personal
r.rule({ workspace = 'name:terminal-personal', default = true, on_created_empty = 'alacritty' })
r.rule({ workspace = 'name:browser-personal', default = false, on_created_empty =
'chromium --profile-directory="Profile 1"' })
r.rule({ workspace = 'name:gmail-personal', default = false, on_created_empty =
'chromium --app=https://gmail.com --profile-directory="Profile 1"' })
r.rule({ workspace = 'name:whatsapp-personal', default = false, on_created_empty =
'chromium --app=https://web.whatsapp.com --profile-directory="Profile 1"' })
r.rule({ workspace = 'name:calendar-personal', default = false, on_created_empty =
'chromium --app=https://calendar.google.com --profile-directory="Profile 1"' })
r.rule({ workspace = 'name:youtube-personal', default = false, on_created_empty =
'chromium --app=https://youtube.com --profile-directory="Profile 1"' })
r.rule({ workspace = 'name:meet-personal', default = false, on_created_empty =
'chromium --app=https://meet.google.com --profile-directory="Profile 1"' })
r.rule({ workspace = 'name:discord-personal', on_created_empty = 'vesktop --ozone-platform-hint=auto' })
r.rule({ workspace = 'name:claude-personal', default = false, on_created_empty =
'chromium --app=https://claude.ai/new --profile-directory="Profile 1"' })
r.rule({ workspace = 'name:github-personal', default = false, on_created_empty =
'chromium --app=https://github.com/ --profile-directory="Profile 1"' })
r.rule({ workspace = 'name:emacs-personal', default = false, on_created_empty = 'emacs' })
r.rule({ workspace = 'name:music-personal', default = false, on_created_empty = 'spotify --disable-gpu' })
r.rule({ workspace = 'name:localhostfe', default = false, on_created_empty = 'chromium --app=http://localhost:3000' })

-- Misc
r.rule({ workspace = 'name:sound', default = false, on_created_empty = 'pavucontrol' })
r.rule({ workspace = 'name:games', default = false, on_created_empty =
'steam --enable-features=UseOzonePlatform --ozone-platform=wayland' })

-- Work
r.rule({ workspace = 'name:terminal-work', default = false, on_created_empty = 'alacritty' })
r.rule({ workspace = 'name:browser-work', default = false, on_created_empty = 'chromium --profile-directory="Profile 2"' })
r.rule({ workspace = 'name:gmail-work', default = false, on_created_empty =
'chromium --app=https://gmail.com --profile-directory="Profile 2"' })
r.rule({ workspace = 'name:calendar-work', default = false, on_created_empty =
'chromium --app=https://calendar.google.com --profile-directory="Profile 2"' })
r.rule({ workspace = 'name:youtube-work', default = false, on_created_empty =
'chromium --app=https://youtube.com --profile-directory="Profile 2"' })
r.rule({ workspace = 'name:meet-work', default = false, on_created_empty =
'chromium --app=https://meet.google.com --profile-directory="Profile 2"' })
r.rule({ workspace = 'name:povio-work', default = false, on_created_empty =
'chromium --app=https://app.povio.com --profile-directory="Profile 2"' })
r.rule({ workspace = 'name:slack-work', default = false, on_created_empty = 'slack' })
r.rule({ workspace = 'name:claude-work', default = false, on_created_empty =
'chromium --app=https://claude.ai/new --profile-directory="Profile 2"' })
r.rule({ workspace = 'name:github-work', default = false, on_created_empty =
'chromium --app=https://github.com/ --profile-directory="Profile 2"' })
