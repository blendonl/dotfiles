-- Daemons & one-shot commands that the old hyprland-execs.conf used to launch.
hl.on('hyprland.start', function()
  -- D-Bus / systemd environment propagation MUST run before anything that
  -- might trigger D-Bus activation of xdg-desktop-portal, otherwise the
  -- portal comes up without WAYLAND_DISPLAY/XDG_CURRENT_DESKTOP and screen
  -- sharing silently picks the wrong backend.
  hl.dispatch(hl.dsp.exec_cmd('systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE QT_QPA_PLATFORMTHEME'))
  hl.dispatch(hl.dsp.exec_cmd('dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE'))

  -- Daemons
  hl.dispatch(hl.dsp.exec_cmd('fcitx5'))
  hl.dispatch(hl.dsp.exec_cmd('dunst'))
  hl.dispatch(hl.dsp.exec_cmd('hypridle'))
  hl.dispatch(hl.dsp.exec_cmd('udiskie &'))
  hl.dispatch(hl.dsp.exec_cmd('qs'))

  -- Clipboard history
  hl.dispatch(hl.dsp.exec_cmd('wl-paste --watch cliphist store &'))
  hl.dispatch(hl.dsp.exec_cmd('wl-paste --type text --watch cliphist store'))
  hl.dispatch(hl.dsp.exec_cmd('wl-paste --type image --watch cliphist store'))

  -- Cursor theme (runtime)
  hl.dispatch(hl.dsp.exec_cmd('hyprctl setcursor Bibata-Modern-Ice-Right 23'))
end)
