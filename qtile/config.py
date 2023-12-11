from libqtile import layout, hook
from libqtile.config import Click, Drag, Key, Group, Match, ScratchPad, DropDown
from libqtile.utils import guess_terminal
from libqtile.lazy import lazy
import binds
import screen
import subprocess


mod = "mod4"
terminal = guess_terminal()
last_client = None

binds.setModAndTerminal(mod, terminal)
keys = binds.setKeys()


screens = screen.getScreens()

# lazy.spawn("autorandr --change home")

opacity = 0.9
y_position = 0.1
x_position = 0.15
height = 0.60
on_focus_lost_hide = True
width = 0.70

groups = [Group(i) for i in "123456789"]


groups.append(
    ScratchPad("scratchpad",
               [
                   DropDown("terminal",
                            '/home/notpc/.config/qtile/alacritty-cwd.sh',
                            opacity=opacity,
                            match=Match(wm_class="Alacritty"),
                            y=y_position,
                            x=x_position,
                            height=height,
                            width=width,
                            on_focus_lost_hide=on_focus_lost_hide,
                            # warp_pointer=warp_pointer
                            ),

                   DropDown("terminal1",
                            terminal,
                            opacity=opacity,
                            y=y_position,
                            x=x_position,
                            height=height,
                            width=width,
                            on_focus_lost_hide=on_focus_lost_hide,
                            # warp_pointer=warp_pointer
                            ),

                   DropDown("browser",
                            "firefox-developer-edition",
                            match=Match(wm_class="firefoxdeveloperedition"),
                            opacity=opacity,
                            y=y_position,
                            x=x_position,
                            height=height,
                            on_focus_lost_hide=on_focus_lost_hide,
                            width=width,
                            # warp_pointer=warp_pointer
                            ),
                   DropDown("discord",
                            "discord",
                            opacity=1.0,
                            match=Match(wm_class="discord"),
                            y=y_position,
                            x=x_position,
                            height=height,
                            on_focus_lost_hide=on_focus_lost_hide,
                            width=width,
                            # warp_pointer=warp_pointer
                            )
               ]
               ),
)

for i in "123456789":
    keys.extend(
        [
            # mod1 + letter of group = switch to group
            Key(
                [mod],
                i,
                lazy.group[i].toscreen(),
                desc="Switch to group {}".format(i),
            ),
            # mod1 + shift + letter of group = switch to & move focused window to group
            Key(
                [mod, "shift"],
                i,
                lazy.window.togroup(i, switch_group=True),
                desc="Switch to & move focused window to group {}".format(
                    i),
            ),
            # Or, use below if you prefer not to switch to that group.
            # # mod1 + shift + letter of group = move focused window to group
            # Key([mod, "shift"], i.name, lazy.window.togroup(i.name),
            #     desc="move focused window to group {}".format(i.name)),
        ]
    )

keys.extend([
    Key(
        [],
        "F1",
        lazy.group["scratchpad"].dropdown_toggle("terminal"),
        desc="alacritty dropdown"
    ),
    Key(
        [],
        "F2",
        lazy.group["scratchpad"].dropdown_toggle("terminal1"),
        desc="alacritty dropdown"
    ),
    Key(
        [],
        "F3",
        lazy.group["scratchpad"].dropdown_toggle("browser"),
        desc="alacritty dropdown"
    ),
    Key(
        [mod],
        "d",
        lazy.group["scratchpad"].dropdown_toggle("discord"),
        desc="dropdown"
    ),
])

layouts = [
    layout.Columns(
        border_focus="#6abf8c",
        border_normal="#6a6a6a",
        border_width=2,
        margin=7

    ),
    layout.MonadTall(
        border_focus="#8f8f8f",
        border_normal="#000000",
        border_width=2,
        margin=10

    ),
    # layout.Max(),
    layout.Stack(num_stacks=2),
    layout.Bsp(),
    layout.Matrix(),
    layout.MonadWide(),
    layout.RatioTile(),
    layout.Tile(),
    layout.TreeTab(),
    layout.VerticalTile(),
    layout.Zoomy(),
]

widget_defaults = dict(
    font="HackNerdFontMono",
    fontsize=14,
    padding=7,
)
extension_defaults = widget_defaults.copy()


# Drag floating layouts.
mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(),
         start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(),
         start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]

dgroups_key_binder = None
dgroups_app_rules = []  # type: list
follow_mouse_focus = True
bring_front_click = False
floats_kept_above = True
cursor_warp = False
floating_layout = layout.Floating(
    border_focus="#6abf8c",
    border_normal=None,
    border_width=1,
    float_rules=[
        # Run the utility of `xprop` to see the wm class and name of an X client.
        *layout.Floating.default_float_rules,
        Match(wm_class="confirmreset"),  # gitk
        Match(wm_class="makebranch"),  # gitk
        Match(wm_class="maketag"),  # gitk
        Match(wm_class="ssh-askpass"),  # ssh-askpass
        Match(title="branchdialog"),  # gitk
        Match(title="pinentry"),  # GPG key password entry
    ]
)
auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True

# If things like steam games want to auto-minimize themselves when losing
# focus, should we respect this or not?
auto_minimize = True

# When using the Wayland backend, this can be used to configure input devices.
wl_input_rules = None

# XXX: Gasp! We're lying here. In fact, nobody really uses or cares about this
# string besides java UI toolkits; you can see several discussions on the
# mailing lists, GitHub issues, and other WM documentation that suggest setting
# this string if your java app doesn't work correctly. We may as well just lie
# and say that we're a working one by default.
#
# We choose LG3D to maximize irony: it is a 3D non-reparenting WM written in
# java that happens to be on java's whitelist.
wmname = "LG3D"


@hook.subscribe.startup_once
def autostart_once():
    subprocess.run('/home/notpc/.config/qtile/autostart.sh')


@hook.subscribe.client_focus
def win_focus(current_client):
    last_client = current_client
    print(last_client)
