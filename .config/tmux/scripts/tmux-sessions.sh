#!/usr/bin/env bash

if [[ $# -eq 1 ]]; then
    selected=$1
else
    selected=$(perl -MFile::Find -le '
  my @root_paths = @ARGV;
  
  # Print root paths first
  for my $path (@root_paths) {
    print $path if -d $path;
  }
  
  sub wanted {
    if (/^\../) {$File::Find::prune = 1; return}

    if(index($File::Find::name, "/mnt/data/personal/dotfiles/.config") == 0) {
        my $relative_path = $File::Find::name;
        $relative_path =~ s|^/mnt/data/personal/dotfiles/.config/||;  

        if ($relative_path !~ /\//) {
            print $File::Find::name;  
        }
        return;

    }

    if(index($File::Find::name, "/home/notpc/dotfiles/.config") == 0) {
        my $relative_path = $File::Find::name;
        $relative_path =~ s|^/home/notpc/dotfiles/.config/||;  

        if ($relative_path !~ /\//) {
            print $File::Find::name;  
        }
        return;

    }

    if (-d && -e "$_/.git") {
       print $File::Find::name; $File::Find::prune = 1;
    } 

    if (-d && -e "$_/apps") {
        my $file = $File::Find::name;
        my $folder = "$file/apps";

        opendir(my $dh, "$folder") or die "Cant open dir: $folder";
        while (my $entry = readdir($dh)) {
            next if $entry =~ /^\.\.?$/;
            my $path = "$folder/$entry";
            print "$path" if -d $path;
        }

    }

  }; find \&wanted, @ARGV' ~/.config/nvim ~/dotfiles/.config ~/work ~/notes ~/personal /mnt/data/work /mnt/data/personal/dotfiles/.config /mnt/data/personal /mnt/data/notes | fzf-tmux -p --no-extended)
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
