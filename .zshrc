eval "$(starship init zsh)"


# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
 COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder
# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='nvim'
else
  export EDITOR='vi'
fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"


### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust



### End of Zinit's installer chunk

# compinit must run before fzf-tab (per fzf-tab's docs).
# Deferred compdefs from the turbo block below are replayed via zicdreplay.
autoload -Uz compinit && compinit

# fzf-tab: load after compinit but before widget-wrapping plugins
# (autosuggestions, fast-syntax-highlighting) — the wrong order makes
# completion insert text at the wrong offset, duplicating typed characters.
zinit light Aloxaf/fzf-tab

zinit snippet OMZ::plugins/git/git.plugin.zsh
zinit load 'zsh-users/zsh-history-substring-search'
zinit light joshskidmore/zsh-fzf-history-search

zinit wait lucid light-mode for \
  atinit"zicompinit; zicdreplay" \
      zdharma-continuum/fast-syntax-highlighting \
  blockf atpull'zinit creinstall -q .' \
      zsh-users/zsh-completions

# Load autosuggestions synchronously (not in turbo mode) so it never races
# with typing at a fresh prompt — turbo loading was inserting ghost-text
# suggestions into half-typed commands.
zinit light zsh-users/zsh-autosuggestions


bindkey "^P" up-line-or-search
bindkey "^N" down-line-or-search

bindkey '^P' history-substring-search-up
bindkey '^N' history-substring-search-down
bindkey "^R" history-incremental-search-backward

set -o vi

HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
setopt appendhistory

setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# NOTE: compinit is already handled by zinit (zicompinit/zicdreplay above);
# running it again here just slows down shell startup.

export NOTE_PATH="/mnt/data/notes"

export PATH="/mnt/data/personal/mkanban/dist:$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH:/home/notpc/.local/bin"
# Android SDK: only export ANDROID_HOME when an SDK actually exists there,
# otherwise Expo/adb warn about a non-existing path on every run. Plain `adb`
# from the android-tools package lives in /usr/bin and needs none of this.
unset ANDROID_HOME ANDROID_SDK_ROOT
for _sdk in "$HOME/Android/Sdk" "$HOME/.local/share/Android/Sdk" /opt/android-sdk; do
  if [[ -d $_sdk ]]; then
    export ANDROID_HOME=$_sdk
    export ANDROID_SDK_ROOT=$_sdk
    export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin
    break
  fi
done
unset _sdk

[[ -d /usr/lib/jvm/java-17-openjdk ]] && export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
# source ~/.config/kitty/pasteimage.sh

# opencode
export PATH=/home/notpc/.opencode/bin:$PATH

export ENABLE_LSP_TOOL=1

alias cadence-build="CGO_ENABLED=1 CADENCE_BACKEND_URL=https://cadence-api.blendonl.com CADENCE_FRONTEND_URL=https://cadence.blendonl.com make build && sudo CADENCE_BACKEND_URL=https://cadence-api.blendonl.com CADENCE_FRONTEND_URL=https://cadence.blendonl.com make install"



# kimi-code
export PATH="/home/notpc/.kimi-code/bin:$PATH"
source /usr/share/nvm/init-nvm.sh
