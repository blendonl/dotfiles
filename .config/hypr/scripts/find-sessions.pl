#!/usr/bin/env perl
use strict;
use warnings;
use File::Find;

my @config_roots = split /,/, shift;
my @monorepo_subs = split /,/, shift;

for my $path (@ARGV) {
    print "$path\n" if -d $path;
}

sub wanted {
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

find \&wanted, @ARGV;
