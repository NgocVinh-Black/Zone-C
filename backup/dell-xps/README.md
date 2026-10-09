# dell-xps backup

A snapshot of the Arch Linux setup on the Dell XPS (`arch-xps`), taken before a reinstall.

- `lists/`: package lists (official and AUR), enabled systemd services, system info, user fonts
- `home/`: dotfiles, `~/.config` (including ElegooSlicer profiles), `~/.local/bin` scripts, user fonts, ble.sh, a dconf dump and the `sddm-zone-thunder` theme sources
- `etc/`: pacman, mkinitcpio, locale, sddm, keyboard and mirrorlist (fstab is only a reference)

## Restore

```bash
git clone -b dell-XPS git@github.com:NgocVinh-Black/Zone-C.git ~/Zone-C
~/Zone-C/backup/dell-xps/restore.sh
```

Then run `./install/install.sh`, then `restore.sh configs`, and reboot. See the top-level README for the full steps.

## Not included

Personal data and account logins are left out on purpose; sign back in after restoring:

- `~/.ssh` (SSH keys)
- Browser profiles (Chrome, Brave, Edge, Opera, Vivaldi) and logins for VS Code, GitHub Desktop and Viber; sign back in, or use browser sync
- `~/.bash_history`, plus Claude, Copilot and Cargo credentials
- Personal folders: `~/Documents`, `~/Downloads`, `~/Pictures`, `~/Projects`, `~/Videos`

Re-run `backup.sh` to refresh the snapshot.
