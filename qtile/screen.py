
from libqtile.config import Screen
from libqtile import bar, widget
from qtile_extras import widget as extrawidgets
from qtile_extras.resources import wallpapers

decoration_group = {
    "padding": 9,
}


def getScreens():
    return [
        Screen(
            top=bar.Bar(
                [
                    extrawidgets.CurrentLayout(),
                    extrawidgets.GroupBox(),
                    extrawidgets.Spacer(length=bar.STRETCH),
                    extrawidgets.Clock(format="%d-%m %a %I:%M %p"),
                    extrawidgets.Spacer(length=bar.STRETCH),
                    extrawidgets.Systray(**decoration_group),
                    extrawidgets.GithubNotifications(),
                    extrawidgets.WifiIcon(),
                    extrawidgets.Mpris2(
                        format='{xesam:title} - {xesam:artist}'
                    ),
                    extrawidgets.Battery()
                ],
                40,
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
    ]
