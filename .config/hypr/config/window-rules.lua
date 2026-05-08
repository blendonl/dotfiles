-- File-dialog windows
hl.window_rule({ name = 'open-file-float', match = { title = '^(Open File)(.*)$' }, float = true })
hl.window_rule({ name = 'select-file-float', match = { title = '^(Select a File)(.*)$' }, float = true })
hl.window_rule({ name = 'choose-wallpaper-float', match = { title = '^(Choose wallpaper)(.*)$' }, float = true })
hl.window_rule({ name = 'open-folder-float', match = { title = '^(Open Folder)(.*)$' }, float = true })
hl.window_rule({ name = 'save-as-float', match = { title = '^(Save As)(.*)$' }, float = true })
hl.window_rule({ name = 'library-float', match = { title = '^(Library)(.*)$' }, float = true })

-- Floating utility windows by class
hl.window_rule({ name = 'new-to-do', match = { class = 'new-to-do' }, size = '45% 25%', float = true })
hl.window_rule({ name = 'checkout', match = { class = 'checkout' }, size = '80% 80%', float = true })
hl.window_rule({ name = 'mkanban', match = { class = 'mkanban' }, size = '80% 80%', float = true })
hl.window_rule({ name = 'neovide', match = { class = 'neovide' }, size = '80% 80%', float = true })

hl.window_rule({ name = 'xdg-portal-float', match = { class = '^(xdg-desktop-portal)$' }, float = true })
hl.window_rule({ name = 'xdg-portal-gnome-float', match = { class = '^(xdg-desktop-portal-gnome)$' }, float = true })
hl.window_rule({ name = 'fragments-float', match = { class = '^(de.haeckerfelix.Fragments)$' }, float = true })
hl.window_rule({ name = 'ags-float', match = { class = '^(com.github.Aylur.ags)$' }, float = true })

-- Hide xwaylandvideobridge
hl.window_rule({ name = 'xvb-opacity', match = { class = '^(xwaylandvideobridge)$' }, opacity = 0.0 })
hl.window_rule({ name = 'xvb-no-anim', match = { class = '^(xwaylandvideobridge)$' }, no_anim = true })

hl.window_rule({
  name = "xwayland-video-bridge-fixes",
  match = { class = "xwaylandvideobridge" },
  no_initial_focus = true,
  no_focus = true,
  no_anim = true,
  no_blur = true,
  max_size = "1 1",
  opacity = 0.0,
})
