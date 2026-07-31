# Dotfiles

## wt-box — isolated test env per git worktree

One command from any linked worktree gives it its own LAN IP (netns via
`ensure-box`), symlinks the main worktree's `.env*` files in, and registers
a local DNS name — so every worktree runs its app on the normal port and you
just open:

```
http://<repo>-<branch>.wt.test:<app-port>
```

```sh
sudo ensure-macvlan     # one-time: macvlan network + host interface
sudo ensure-wt-dns      # one-time: dnsmasq + resolved routing for *.wt.test

wt-box up               # from inside a linked worktree: create + attach
wt-box list             # all worktree boxes
wt-box url              # print this worktree's URL
wt-box down             # stop env, release IP, unregister name
```

Notes:

- `.env*` files are symlinked from the main worktree (except
  `*.example`/`*.sample`/`*.dist`); a file already in the worktree wins.
- Names resolve only on this host (dnsmasq on 127.0.0.1, routed via a
  systemd-resolved `~wt.test` drop-in; Tailscale DNS is untouched).
- Run from the main worktree itself, `wt-box up` just opens a plain
  `box-lite` session — no isolation needed there.
