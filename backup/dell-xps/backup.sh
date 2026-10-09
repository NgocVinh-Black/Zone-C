#!/usr/bin/env bash
# Snapshot this machine's configs and package lists into backup/dell-xps.
# Secrets (browser profiles, SSH keys, tokens, app logins) are deliberately skipped.
set -euo pipefail
OUT="$(cd "$(dirname "$0")" && pwd)"
H="$HOME"
rm -rf "$OUT/home" "$OUT/etc" "$OUT/lists"
mkdir -p "$OUT/home/.config" "$OUT/home/.local/bin" "$OUT/home/.local/share" "$OUT/etc" "$OUT/lists"

# Packages
pacman -Qqen > "$OUT/lists/pkglist-native.txt"
pacman -Qqem > "$OUT/lists/pkglist-aur.txt"
pacman -Q    > "$OUT/lists/pkglist-all-versions.txt"
command -v flatpak >/dev/null && flatpak list --app --columns=application > "$OUT/lists/flatpak.txt" || true
ls -1 "$H/.vscode/extensions" 2>/dev/null | grep -v "\.json$" | sed -E 's/-[0-9]+\.[0-9]+\.[0-9]+.*$//' | sort -u > "$OUT/lists/vscode-extensions.txt" || true

# Services
systemctl list-unit-files --state=enabled --no-legend --no-pager | awk '{print $1}' > "$OUT/lists/systemd-system-enabled.txt"
systemctl --user list-unit-files --state=enabled --no-legend --no-pager | awk '{print $1}' > "$OUT/lists/systemd-user-enabled.txt"

# System info
{
  echo "hostname=$(cat /etc/hostname)"
  echo "user=$USER groups=$(id -nG)"
  echo "shell=$SHELL"
  timedatectl show -p Timezone
  localectl status
  uname -r
} > "$OUT/lists/system-info.txt"
(cd "$H/.local/share/fonts" 2>/dev/null && find . -type f | sort) > "$OUT/lists/user-fonts.txt" || true

# Home dotfiles
for f in .bashrc .bash_profile .bash_logout .blerc .gitconfig .face; do
  [ -e "$H/$f" ] && cp -a "$H/$f" "$OUT/home/"
done

# ~/.config (no browsers, Electron app data, or login stores)
for d in cava easyeffects fastfetch fcitx5 flameshot foot gtk-3.0 gtk-4.0 hypr kitty \
         nautilus qt6ct systemd zone-c yay procps \
         ElegooSlicer code-flags.conf mimeapps.list pavucontrol.ini; do
  [ -e "$H/.config/$d" ] && cp -a "$H/.config/$d" "$OUT/home/.config/"
done
mkdir -p "$OUT/home/.config/Code/User"
for f in settings.json keybindings.json snippets; do
  [ -e "$H/.config/Code/User/$f" ] && cp -a "$H/.config/Code/User/$f" "$OUT/home/.config/Code/User/"
done
command -v dconf >/dev/null && dconf dump / > "$OUT/home/.config/dconf-dump.ini" || true

# SDDM theme sources
for d in sddm-zone-thunder; do
  [ -e "$H/$d" ] && cp -a "$H/$d" "$OUT/home/"
done

# ~/.local (regular scripts only; symlinks into installed apps are recreated by their installers)
find "$H/.local/bin" -maxdepth 1 -type f -exec cp -a {} "$OUT/home/.local/bin/" \;
for d in applications icons easyeffects fonts elegoo-slicer blesh float-cat nautilus; do
  [ -e "$H/.local/share/$d" ] && cp -a "$H/.local/share/$d" "$OUT/home/.local/share/"
done

# /etc files that differ from defaults on this machine
for f in pacman.conf mkinitcpio.conf locale.conf vconsole.conf hostname environment makepkg.conf fstab; do
  [ -r "/etc/$f" ] && cp "/etc/$f" "$OUT/etc/"
done
mkdir -p "$OUT/etc/sddm.conf.d" "$OUT/etc/X11/xorg.conf.d"
cp /etc/sddm.conf.d/* "$OUT/etc/sddm.conf.d/" 2>/dev/null || true
cp /etc/X11/xorg.conf.d/* "$OUT/etc/X11/xorg.conf.d/" 2>/dev/null || true
cp /etc/pacman.d/mirrorlist "$OUT/etc/mirrorlist" 2>/dev/null || true

find "$OUT/home" \( -name "*.lock*" -o -name "*-shm" -o -name "*-wal" \) -delete
rm -rf "$OUT/home/.config/ElegooSlicer/log" "$OUT/home/.config/ElegooSlicer/cache"
# Repo is public: drop the IP-based location cache (the shell refetches it)
python3 -c 'import json,sys;p=sys.argv[1];d=json.load(open(p));d.get("general",{}).pop("location",None);json.dump(d,open(p,"w"),indent=2)' "$OUT/home/.config/zone-c/settings.json"
rm -f "$OUT/home/.local/share/applications/mimeinfo.cache"
echo "Backup written to $OUT"
