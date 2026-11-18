#!/usr/bin/env bash
set -euo pipefail

LOCAL_BIN="$HOME/.local/bin"
FONT_DIR="$HOME/.local/share/fonts"
NERD_FONTS=(FiraCode JetBrainsMono SourceCodePro NerdFontsSymbolsOnly)
MATERIAL_SYMBOLS_URL="https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsRounded%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf"
GABARITO_URL="https://github.com/google/fonts/raw/main/ofl/gabarito/Gabarito%5Bwght%5D.ttf"

export PATH="$LOCAL_BIN:$PATH"

latest_release_tag() {
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" |
    grep -oE '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4
}

install_apt_packages() {
  sudo apt-get update
  sudo apt-get install -y \
    build-essential ca-certificates curl git unzip fontconfig \
    zsh tmux jq stow fzf wl-clipboard \
    lua5.1 liblua5.1-0-dev luarocks \
    alacritty gh \
    fonts-noto-color-emoji
}

install_neovim() {
  if command -v nvim >/dev/null; then return; fi
  sudo snap install nvim --classic
}

node_is_current() {
  command -v node >/dev/null || return 1
  [ "$(node -v | sed 's/^v\([0-9]*\).*/\1/')" -ge 20 ]
}

install_node_and_yarn_berry() {
  if ! node_is_current; then
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt-get install -y nodejs
  fi
  sudo corepack enable
  corepack prepare yarn@stable --activate
}

install_rust() {
  if command -v rustup >/dev/null; then
    rustup update
    return
  fi
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
}

install_starship() {
  if command -v starship >/dev/null; then return; fi
  curl -sS https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$LOCAL_BIN"
}

install_lazygit() {
  if command -v lazygit >/dev/null; then return; fi
  local tag version
  tag=$(latest_release_tag jesseduffield/lazygit)
  version="${tag#v}"
  curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/${tag}/lazygit_${version}_linux_x86_64.tar.gz" |
    tar -xz -C "$LOCAL_BIN" lazygit
}

install_posting() {
  if ! command -v uv >/dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
  fi
  "$LOCAL_BIN/uv" tool install --force posting
}

install_nerd_fonts() {
  local tag font tmp
  tag=$(latest_release_tag ryanoasis/nerd-fonts)
  for font in "${NERD_FONTS[@]}"; do
    if [ -d "$FONT_DIR/$font" ]; then continue; fi
    tmp=$(mktemp -d)
    curl -fsSL -o "$tmp/$font.zip" \
      "https://github.com/ryanoasis/nerd-fonts/releases/download/${tag}/${font}.zip"
    unzip -qo "$tmp/$font.zip" -d "$FONT_DIR/$font" -x 'README*' 'LICENSE*' 'OFL*'
    rm -rf "$tmp"
  done
}

install_variable_fonts() {
  curl -fsSL -o "$FONT_DIR/Gabarito.ttf" "$GABARITO_URL"
  curl -fsSL -o "$FONT_DIR/MaterialSymbolsRounded.ttf" "$MATERIAL_SYMBOLS_URL"
}

refresh_font_cache() {
  fc-cache -f "$FONT_DIR"
}

stow_dotfiles() {
  cd "$HOME/dotfiles"
  stow .
}

use_zsh_as_login_shell() {
  local zsh_path
  zsh_path=$(command -v zsh)
  if [ "$SHELL" = "$zsh_path" ]; then return; fi
  chsh -s "$zsh_path"
}

mkdir -p "$LOCAL_BIN" "$FONT_DIR"

install_apt_packages
install_neovim
install_node_and_yarn_berry
install_rust
install_starship
install_lazygit
install_posting
install_nerd_fonts
install_variable_fonts
refresh_font_cache
stow_dotfiles
use_zsh_as_login_shell

echo "Done. Restart your terminal for zsh, rust and node to be on PATH."
