# dell-xps backup

A snapshot of the Arch Linux setup on the Dell XPS (`arch-xps`), taken before a reinstall.

- `lists/`: package lists (official and AUR), enabled systemd services, system info, user fonts
- `home/`: dotfiles, `~/.config`, `~/.local/bin` scripts, a dconf dump
- `etc/`: pacman, mkinitcpio, locale, sddm, keyboard and mirrorlist (fstab is only a reference)

## Restore

```bash
git clone -b dell-XPS git@github.com:NgocVinh-Black/Zone-C.git ~/Zone-C
~/Zone-C/backup/dell-xps/restore.sh
```

Then run the Zone-C installer and reboot.

## Not included (repo is public)

These have to be copied by hand (USB or external drive):

- `~/.ssh` (SSH keys)
- Browser profiles (Chrome, Brave, Edge, Opera, Vivaldi) and logins for VS Code, GitHub Desktop and Viber; sign back in, or use browser sync
- `~/.local/share/fonts` (Iosevka Nerd Font, ~760 MB): `sudo pacman -S ttf-iosevka-nerd`
- `~/Documents`, `~/Projects`, `~/Pictures`, `~/Videos`, `~/Downloads`
- ElegooSlicer profiles (`~/.config/ElegooSlicer`)

Re-run `backup.sh` to refresh the snapshot.
