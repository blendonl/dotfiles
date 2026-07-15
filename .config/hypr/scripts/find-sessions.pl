#!/usr/bin/env perl
use strict;
use warnings;
use File::Find;

my $max_depth = shift // 0;
my @config_roots = split /,/, shift;
my @monorepo_subs = split /,/, shift;

for my $path (@ARGV) {
    print "$path\n" if -d $path;
}

sub wanted {
    # Enforce max depth (0 = unlimited)
    if ($max_depth > 0) {
        my $top_depth = () = ($File::Find::topdir =~ /\//g);
        my $current_depth = () = ($File::Find::name =~ /\//g);
        if ($current_depth - $top_depth > $max_depth) {
            $File::Find::prune = 1;
            return;
        }
    }

    return ($File::Find::prune = 1) if /^\../;

    for my $root (@config_roots) {
        if (index($File::Find::name, $root) == 0) {
            (my $rel = $File::Find::name) =~ s|^\Q$root\E/||;
            print "$File::Find::name\n" if $rel !~ /\//;
            return;
        }
    }

    if (-d && -e "$_/.git") {
        print "$File::Find::name\n";
        $File::Find::prune = 1;
        for my $sub (@monorepo_subs) {
            my $folder = "$File::Find::name/$sub";
            next unless -d $folder;
            opendir(my $dh, $folder) or next;
            while (my $entry = readdir($dh)) {
                next if $entry =~ /^\.\.?$/;
                my $path = "$folder/$entry";
                print "$path\n" if -d $path;
            }
            closedir($dh);
        }
    }
}

@ARGV = grep { -d $_ } @ARGV;
find \&wanted, @ARGV;
