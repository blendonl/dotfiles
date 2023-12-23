# Dotfiles

my dotfiles

## Installation

I'm using arch so...



### yay
```   
pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si 
```

### WM, Launcher, Notification-Daemon etc
```   
yay -S neovim qtile qtile-extras lightdm rofi dunst alacritty pavu-control
```

### Dependencies

```   
yay -S python-dbus-next inetutils alsa-utils

```

