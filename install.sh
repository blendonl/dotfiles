#!/usr/bin/env bash

if ! command -v yay &> /dev/null 
then
  echo  Installing Yay

  sudo pacman -S --needed git base-devel
  git clone https://aur.archlinux.org/yay.git ~/yay
  cd ~/yay
  makepkg -si
  sleep 3
  rm -rf ~/yay
fi


yay -S --needed  hyprland-git hyprcursor-git hyprgraphics-git hyprlang-git hyprlock-git hyprutils-git 
yay -S --needed  xdg-desktop-portal xdg-desktop-portal-gnome xdg-desktop-portal-gtk xdg-desktop-protal-hyprland
yay -S --needed  noto-fonts-emoji ttf-firacode-nerd ttf-gabarito-git ttf-jetbrains-mono-nerd ttf-material-symbols-variable-git ttf-nerd-fonts-symbols ttf-sourcecodepro-nerd 
yay -S --needed  tmux zsh jq eww
yay -S --needed  fzf npm yarn-berry cargo rustc luarocks lua51
yay -S --needed  alacritty neovim-git
yay -S --needed  sherlock-launcher-bin qutebrowser 
yay -S --needed  dunst wl-paste wl-copy udiskie
yay -S --needed  github-cli lazygit

curl -sS https://starship.rs/install.sh | sh


git clone https://www.github.com/blendonl/dotfiles ~/dotfiles
git clone https://www.github.com/blendonl/nvim ~/.config/nvim



mkdir -p ~/notes/general/
mkdir -p ~/notes/personal/
mkdir -p ~/notes/work/

chsh -s $(which zsh) 



