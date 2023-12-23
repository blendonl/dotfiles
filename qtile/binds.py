
from libqtile.config import Key
from libqtile.lazy import lazy

mod = ""
terminal = ""


def setModAndTerminal(mod, terminal):
    globals()['mod'] = mod
    globals()['terminal'] = terminal


def setKeys():
    return [
        # A list of available commands that can be bound to keys can be found
        # at https://docs.qtile.org/en/latest/manual/config/lazy.html

        # Switch between windows
        Key([mod], "h", lazy.layout.left(), desc="Move focus to left"),
        Key([mod], "l", lazy.layout.right(), desc="Move focus to right"),
        Key([mod], "j", lazy.layout.down(), desc="Move focus down"),
        Key([mod], "k", lazy.layout.up(), desc="Move focus up"),
        Key([mod], "space", lazy.layout.next(),
            desc="Move window focus to other window"),

        # Move windows between left/right columns or move up/down in current stack.
        # Moving out of range in Columns layout will create new column.
        Key([mod, "shift"], "h", lazy.layout.shuffle_left(),
            desc="Move window to the left"),
        Key([mod, "shift"], "l", lazy.layout.shuffle_right(),
            desc="Move window to the right"),
        Key([mod, "shift"], "j", lazy.layout.shuffle_down(),
            desc="Move window down"),
        Key([mod, "shift"], "k", lazy.layout.shuffle_up(), desc="Move window up"),

        # Grow windows. If current window is on the edge of screen and direction
        # will be to screen edge - window would shrink.
        Key([mod, "control"], "h", lazy.layout.grow_left(),
            desc="Grow window to the left"),
        Key([mod, "control"], "l", lazy.layout.grow_right(),
            desc="Grow window to the right"),
        Key([mod, "control"], "j", lazy.layout.grow_down(),
            desc="Grow window down"),
        Key([mod, "control"], "k", lazy.layout.grow_up(), desc="Grow window up"),
        Key([mod], "n", lazy.layout.normalize(), desc="Reset all window sizes"),

        # Toggle between split and unsplit sides of stack.
        # Split = all windows displayed
        # Unsplit = 1 window displayed, like Max layout, but still with
        # multiple stack panes
        Key(
            [mod, "shift"],
            "Return",
            lazy.layout.toggle_split(),
            desc="Toggle between split and unsplit sides of stack",
        ),
        Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
        Key([mod], "v", lazy.spawn(
            "/home/notpc/.config/rofi/applets/bin/volume.sh"), desc="Launch terminal"),

        # Volume
        Key([], "XF86AudioLowerVolume", lazy.spawn(
            "amixer -Mq set Master,0 5%- unmute"), desc="volume down"),
        Key([], "XF86AudioRaiseVolume", lazy.spawn(
            "amixer -Mq set Master,0 5%+ unmute"), desc="volume up"),
        Key([], "XF86AudioMute", lazy.spawn(
            "amixer set Master toggle"), desc="Mute sound"),

        # Music
        Key([], "XF86AudioNext", lazy.spawn(
            "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next"),
            desc="Mute sound"),

        Key([], "XF86AudioPrev", lazy.spawn(
            "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous"),
            desc="Mute sound"),
        Key([], "XF86AudioPlay", lazy.spawn(
            "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause"),
            desc="Mute sound"),


        # Toggle between different layouts as defined below
        Key([mod], "Tab", lazy.next_layout(), desc="Toggle between layouts"),
        Key([mod], "w", lazy.window.kill(), desc="Kill focused window"),
        Key(
            [mod],
            "f",
            lazy.window.toggle_fullscreen(),
            desc="Toggle fullscreen on the focused window",
        ),
        Key([mod], "t", lazy.window.toggle_floating(),
            desc="Toggle floating on the focused window"),
        Key([mod, "control"], "r", lazy.reload_config(), desc="Reload the config"),
        Key([mod, "control"], "q", lazy.spawn(
            "/home/notpc/.config/rofi/powermenu/type-1/powermenu.sh"), desc="Shutdown Qtile"),
        Key([mod], "q", lazy.spawn('dm-tool switch-to-greeter'), desc="Shutdown Qtile"),
        Key([mod], "r", lazy.spawn("/home/notpc/.config/rofi/launchers/type-1/launcher.sh"),
            desc="Spawn a command using a prompt widget"),
    ]
