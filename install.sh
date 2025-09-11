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
yay -S --needed  tmux zsh jq eww stow wl-paste wl-copy dunst udiskie
yay -S --needed  fzf npm yarn-berry cargo rustc luarocks lua51
yay -S --needed  alacritty neovim-git sherlock-launcher-bin qutebrowser
yay -S --needed  github-cli lazygit slack-desktop vencord posting 

curl -sS https://starship.rs/install.sh | sh


git clone https://www.github.com/blendonl/dotfiles ~/dotfiles
git clone https://www.github.com/blendonl/nvim ~/.config/nvim

cd ~/dotfiles/ 
stow .

chsh -s $(which zsh) 



