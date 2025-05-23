#!/usr/bin/env bash

if [[ $# -eq 1 ]]; then
    selected=$1
else
    selected=$(perl -MFile::Find -le '
  sub wanted {
    if (/^\../) {$File::Find::prune = 1; return}

    if(index($File::Find::name, "$ENV{HOME}/.config") == 0) {
        my $relative_path = $File::Find::name;
        $relative_path =~ s|^$ENV{HOME}/.config/||;  

        if ($relative_path !~ /\//) {
            print $File::Find::name;  
        }
        return;

    }

    if (-d && -e "$_/.git") {
       print $File::Find::name; $File::Find::prune = 1;
    } 

  }; find \&wanted, @ARGV' ~/work ~/.config ~/personal ~/notes | fzf-tmux -p --no-extended)
fi

if [[ -z $selected ]]; then
    exit 0
fi

selected_name=$(basename "$selected" | tr . _)
tmux_running=$(pgrep tmux)

if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
    tmux new-session -s "$selected_name" -c "$selected"
    exit 0
fi

if ! tmux has-session -t="$selected_name" 2>/dev/null; then
    tmux new-session -ds "$selected_name" -c "$selected"
fi

tmux switch-client -t "$selected_name"
