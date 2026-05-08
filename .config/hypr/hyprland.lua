require('config.env')
require('config.general')
require('config.monitor')
require('config.window-rules')
require('config.startup')
require('workspaces')
require('keybinds.submaps')

local mainMod = 'SUPER'


hl.bind(mainMod .. ' + C', hl.dsp.window.close())
hl.bind(mainMod .. ' + F',
  hl.dsp.exec_cmd('wl-kbptr -o modes=floating,click -o mode_floating.source=detect -o mode_click.button=left'))
hl.bind(mainMod .. ' + G',
  hl.dsp.exec_cmd('wl-kbptr -o modes=floating,click -o mode_floating.source=detect -o mode_click.button=right'))

-- Focus / window movement
hl.bind(mainMod .. ' + H', hl.dsp.focus({ direction = 'l' }))
hl.bind(mainMod .. ' + J', hl.dsp.focus({ direction = 'd' }))
hl.bind(mainMod .. ' + K', hl.dsp.focus({ direction = 'u' }))
hl.bind(mainMod .. ' + L', hl.dsp.focus({ direction = 'r' }))
hl.bind(mainMod .. ' + P', hl.dsp.focus({ window = 'floating' }))
hl.bind(mainMod .. ' + T', hl.dsp.focus({ window = 'tiled' }))
hl.bind(mainMod .. ' + SHIFT + H', hl.dsp.window.move({ direction = 'l' }))
hl.bind(mainMod .. ' + SHIFT + J', hl.dsp.window.move({ direction = 'd' }))
hl.bind(mainMod .. ' + SHIFT + K', hl.dsp.window.move({ direction = 'u' }))
hl.bind(mainMod .. ' + SHIFT + L', hl.dsp.window.move({ direction = 'r' }))

-- Resize active window
hl.bind(mainMod .. ' + CONTROL + H', hl.dsp.window.resize({ x = -10, y = 0 }), { repeating = true })
hl.bind(mainMod .. ' + CONTROL + J', hl.dsp.window.resize({ x = 0, y = 10 }), { repeating = true })
hl.bind(mainMod .. ' + CONTROL + K', hl.dsp.window.resize({ x = 0, y = -10 }), { repeating = true })
hl.bind(mainMod .. ' + CONTROL + L', hl.dsp.window.resize({ x = 10, y = 0 }), { repeating = true })

-- Workspace
hl.bind(mainMod .. ' + TAB',
  hl.dsp.workspace.swap_monitors({ monitor1 = "HDMI-A-1", monitor2 = "eDP-1" }))

-- Audio
hl.bind('XF86AudioMute', hl.dsp.exec_cmd('wpctl set-volume @DEFAULT_AUDIO_SINK@ 0%'), { locked = true })
hl.bind('XF86AudioRaiseVolume', hl.dsp.exec_cmd('wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+'),
  { locked = true, repeating = true })
hl.bind('XF86AudioLowerVolume', hl.dsp.exec_cmd('wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-'),
  { locked = true, repeating = true })
hl.bind('XF86AudioPrev', hl.dsp.exec_cmd('playerctl previous || playerctl position 0'), { locked = true })
hl.bind('XF86AudioNext', hl.dsp.exec_cmd('playerctl next || playerctl position 0'), { locked = true })
hl.bind('XF86AudioPlay', hl.dsp.exec_cmd('playerctl play-pause'), { locked = true })

-- Brightness
hl.bind('XF86MonBrightnessUp', hl.dsp.exec_cmd('brightnessctl set +5%'), { locked = true, repeating = true })
hl.bind('XF86MonBrightnessDown', hl.dsp.exec_cmd('brightnessctl set 5%-'), { locked = true, repeating = true })

-- Lid switch
hl.bind('switch:off', hl.dsp.exec_cmd('loginctl lock-session && systemctl suspend'), { locked = true })

hl.bind(mainMod .. ' + I', hl.dsp.exec_cmd('alacritty'))
