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


yay -S --needed --no-confirm hyprland-git hyprcursor-git hyprgraphics-git hyprlang-git hyprlock-git hyprutils-git 
yay -S --needed --no-confirm xdg-desktop-portal xdg-desktop-portal-gnome xdg-desktop-portal-gtk xdg-desktop-protal-hyprland
yay -S --needed --no-confirm noto-fonts-emoji ttf-firacode-nerd ttf-gabarito-git ttf-jetbrains-mono-nerd ttf-material-symbols-variable-git ttf-nerd-fonts-symbols ttf-sourcecodepro-nerd 
yay -S --needed --no-confirm tmux zsh
yay -S --needed --no-confirm fzf npm yarn-berry cargo rustc luarocks lua51
yay -S --needed --no-confirm alacritty neovim-git
yay -S --needed --no-confirm sherlock-launcher-bin qutebrowser 
yay -S --needed --no-confirm dunst wl-paste wl-copy udiskie
yay -S --needed --no-confirm github-cli lazygit

curl -sS https://starship.rs/install.sh | sh


git clone https://www.github.com/blendonl/dotfiles ~/dotfiles
git clone https://www.github.com/blendonl/nvim ~/.config/nvim

ln -s ~/dotfiles/.config/hypr ~/.config/hypr
ln -s ~/dotfiles/.config/alacritty ~/.config/alacritty
ln -s ~/dotfiles/.config/sherlock ~/.config/sherlock
ln -s ~/dotfiles/.tmux.conf ~/.tmux.conf
ln -s ~/dotfiles/.zshrc ~/.zshrc


mkdir -p ~/notes/general/
mkdir -p ~/notes/personal/
mkdir -p ~/notes/work/

chsh -s $(which zsh) 



