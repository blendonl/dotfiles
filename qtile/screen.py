
from libqtile.config import Screen
from libqtile import bar, widget
from libqtile.lazy import lazy
from qtile_extras import widget as extrawidgets
from qtile_extras.widget.decorations import RectDecoration
from qtile_extras.resources import wallpapers

decoration_group = {
    "decorations": [
        RectDecoration(colour="#004040", radius=10,
                       filled=False, padding_y=4, group=True)
    ],
    "padding": 7,
}


def getScreens():
    return [
        Screen(
            top=bar.Bar(
                [
                    extrawidgets.CurrentLayout(**decoration_group),
                    # widget.CurrentLayout(),
                    extrawidgets.GroupBox(),
                    extrawidgets.Prompt(),
                    extrawidgets.Spacer(length=bar.STRETCH),
                    extrawidgets.Clock(format="%d-%m %a %I:%M %p"),
                    extrawidgets.Spacer(length=bar.STRETCH),
                    extrawidgets.Systray(),
                    extrawidgets.StatusNotifier(),
                    extrawidgets.UPowerWidget(),
                    extrawidgets.WiFiIcon(),
                    extrawidgets.GithubNotifications(),
                    extrawidgets.Mpris2(),
                    widget.Sep(),
                    extrawidgets.Battery(
                        format="{percent:2.0%}({hour:d}:{min:02d}) {watt:.2f} W"),
                    # widget.WindowName(),
                    # widget.Systray(),
                ],
                32,
                margin=7,
                # border_width=[2, 0, 2, 0],  # Draw top and bottom borders
                # border_color=["ff00ff", "000000", "ff00ff", "000000"]  # Borders are magenta
            ),
            wallpaper=wallpapers.WALLPAPER_TRIANGLES,
            wallpaper_mode="fill",
            # You can uncomment this variable if you see that on X11 floating resize/moving is laggy
            # By default we handle these events delayed to already improve performance, however your system might still be struggling
            # This variable is set to None (no cap) by default, but you can set it to 60 to indicate that you limit it to 60 events per second
            # x11_drag_polling_rate = 60,
        ),
        Screen(
            top=bar.Bar(
                [
                    extrawidgets.CurrentLayout(**decoration_group),
                    # widget.CurrentLayout(),
                    widget.GroupBox(),
                    widget.Prompt(),
                    widget.Spacer(),
                    # widget.WindowName(),
                    widget.Chord(
                        chords_colors={
                            "launch": ("#ff0000", "#ffffff"),
                        },
                        name_transform=lambda name: name.upper(),
                    ),
                    extrawidgets.Systray(**decoration_group),
                    # widget.TextBox("default config", name="default"),
                    # widget.TextBox("Press &lt;M-r&gt; to spawn", foreground="#d75f5f"),
                    # NB Systray is incompatible with Wayland, consider using StatusNotifier instead
                    # widget.StatusNotifier(),
                    # widget.Systray(),
                    extrawidgets.Clock(format="%d-%m-%Y %a %I:%M %S %p"),
                    widget.QuickExit(),
                ],
                28,
                # border_width=[2, 0, 2, 0],  # Draw top and bottom borders
                # border_color=["ff00ff", "000000", "ff00ff", "000000"]  # Borders are magenta
            ),
            # You can uncomment this variable if you see that on X11 floating resize/moving is laggy
            # By default we handle these events delayed to already improve performance, however your system might still be struggling
            # This variable is set to None (no cap) by default, but you can set it to 60 to indicate that you limit it to 60 events per second
            # x11_drag_polling_rate = 60,
        ),
    ]
