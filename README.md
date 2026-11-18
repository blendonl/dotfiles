# Dotfiles

My Arch Linux desktop: Hyprland, tmux, Neovim and zsh, plus the shell tools
in `bin/` that tie projects, git worktrees and tmux sessions together.
Everything is symlinked into place with GNU Stow.

## What's here

| Path | What |
| --- | --- |
| `.config/hypr` | Hyprland, configured in Lua: `config/` (monitors, env, rules, startup), `keybinds/` with submaps, `session/` (session and workspace picker), `scripts/`, plus `hyprlock.conf` and `hypridle.conf` |
| `.config/quickshell` | Quickshell widgets started with Hyprland: submap indicator, task, agenda and planner windows |
| `.config/{waybar,eww,ags}` | Bar and widget configs |
| `.config/{dunst,swaync,mako}`, `.config/wlogout` | Notifications and the logout menu |
| `.config/{rofi,walker,sherlock,wofi}` | Launchers; Hyprland's launcher binds use `rofi` |
| `.config/{alacritty,ghostty,kitty}` | Terminals |
| `.config/nvim` | Neovim with lazy.nvim; one plugin spec per file in `lua/plugins/` |
| `.config/tmux` | tmux: backtick prefix, popups for the pickers in `bin/`, custom modes with which-key hints in `modes/` and `scripts/modes/` |
| `.zshrc` | zsh with zinit plugins, fzf-tab and the starship prompt |
| `.config/{matugen,wal}`, `.config/fontconfig` | Theming and fonts |
| `.config/{qutebrowser,lazygit,taskell,posting,doom}` | Other apps |
| `bin/` | Shell tools, see below |

### bin/

| Script | What |
| --- | --- |
| `box-lite` | fzf project picker; each project is a session on the default tmux server, optionally isolated on its own LAN IP (`@net`). tmux: prefix `B` |
| `switch-worktree-lite` | Switch between the current repo's worktrees as box-lite sessions. tmux: prefix `W` |
| `app-picker` | Pick an app under `apps/` or `packages/` in a monorepo and open a session for it. tmux: prefix `a` |
| `box-picker`, `box-switch-worktree` | Older variant of the two pickers above, with one tmux server per project. tmux: prefix `b` and `w` |
| `project-picker`, `switch-worktree`, `ensure-compose` | podman-compose flow with one dev container per worktree |
| `ensure-box-browser` | Chromium running inside a box's network namespace |
| `worktree-picker`, `wt-switch` | Old distrobox-based worktree switcher |
| `wt-box`, `ensure-box`, `box-vnc-pw`, `ensure-macvlan`, `ensure-wt-dns` | Per-worktree network isolation, see [wt-box](#worktree-environments-wt-box) |

## Layout

The repository mirrors `$HOME`: `.config/*` ends up in `~/.config/`, `bin/`
in `~/bin/`, `.zshrc` in `~/.zshrc`. Running `stow .` in the repo creates
the symlinks. Stow links into the parent of the directory it runs in, so the
repo has to live at `~/dotfiles`. `.stow-local-ignore` keeps `.git`,
`.gitignore`, `.gitmodules` and `install.sh` out of `$HOME`.

## Install

On a fresh Arch install:

```sh
git clone https://github.com/blendonl/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh`:

1. installs `yay` from the AUR if it is missing (needs `git` and
   `base-devel`, which it installs with pacman);
2. installs the packages with `yay -S --needed`: the Hyprland `-git` stack
   and hyprlock, the xdg-desktop-portal backends (gnome, gtk, hyprland),
   fonts, `tmux zsh jq eww stow wl-clipboard dunst udiskie cliphist`,
   toolchains (`fzf npm yarn-berry cargo rustc luarocks lua51`),
   `alacritty neovim-git sherlock-launcher-bin qutebrowser` and
   `github-cli lazygit slack-desktop vencord posting`;
3. installs starship with its official install script;
4. runs `stow .` from `~/dotfiles`;
5. makes zsh the login shell with `chsh`.

Stow refuses to replace real files, so move any existing configs out of the
way first. tmux plugins are not vendored: clone
[tpm](https://github.com/tmux-plugins/tpm) to `~/.config/tmux/plugins/tpm`
and press prefix + `I` inside tmux.

Some configs assume this machine's layout: projects under
`/mnt/data/personal` and `/mnt/data/work`, notes under `/mnt/data/notes`.

## Worktree environments (wt-box)

`wt-box up`, run in a linked git worktree, gives that worktree its own LAN
IP, symlinks the main worktree's `.env*` files in and registers
`<repo>-<branch>.wt.test`, so every worktree can run the app on its normal
port:

```sh
sudo ensure-macvlan     # one-time: macvlan network + host interface
sudo ensure-wt-dns      # one-time: dnsmasq + resolved routing for *.wt.test

wt-box up               # from inside a linked worktree: create + attach
wt-box list             # all worktree boxes
wt-box url              # print this worktree's URL
wt-box down             # stop env, release IP, unregister name
```

These scripts, together with `box-lite` and `switch-worktree-lite`, now
live in their own repository,
[blendonl/wt-box](https://github.com/blendonl/wt-box), which has the full
setup, the sudoers rule and the security notes. The copies in `bin/` stay
here until this machine switches over.
