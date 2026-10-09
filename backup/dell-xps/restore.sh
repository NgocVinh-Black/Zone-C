#!/usr/bin/env bash
# Restore a fresh Arch install to match the dell-xps snapshot.
# Run as your normal user (not root) after cloning Zone-C and checking out dell-XPS.
set -euo pipefail
SRC="$(cd "$(dirname "$0")" && pwd)"

restore_home() {
  echo "==> Home configs"
  cp -a "$SRC/home/." "$HOME/"
  [ -f "$HOME/.config/dconf-dump.ini" ] && dconf load / < "$HOME/.config/dconf-dump.ini"
  fc-cache -f >/dev/null 2>&1 || true
}

# "restore.sh configs" only copies the home configs back (use after the Zone-C installer)
if [ "${1:-}" = configs ]; then
  restore_home
  echo "Done. Log out and back in (or reboot)."
  exit 0
fi

echo "==> /etc (pacman, mkinitcpio, locale, sddm, keyboard)"
sudo cp "$SRC/etc/pacman.conf" "$SRC/etc/makepkg.conf" "$SRC/etc/mkinitcpio.conf" \
        "$SRC/etc/locale.conf" "$SRC/etc/vconsole.conf" "$SRC/etc/environment" /etc/
sudo cp "$SRC/etc/mirrorlist" /etc/pacman.d/mirrorlist
sudo mkdir -p /etc/sddm.conf.d /etc/X11/xorg.conf.d
sudo cp "$SRC"/etc/sddm.conf.d/* /etc/sddm.conf.d/
sudo cp "$SRC"/etc/X11/xorg.conf.d/* /etc/X11/xorg.conf.d/
sudo hostnamectl set-hostname "$(cat "$SRC/etc/hostname")"
sudo timedatectl set-timezone Asia/Ho_Chi_Minh
# fstab is NOT copied: partition UUIDs change on reinstall. See etc/fstab for reference.

echo "==> Official packages"
sudo pacman -Syu --needed - < "$SRC/lists/pkglist-native.txt"

echo "==> AUR packages (via yay)"
if ! command -v yay >/dev/null; then
  tmp="$(mktemp -d)"; git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
  (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
fi
grep -v -- '-debug$' "$SRC/lists/pkglist-aur.txt" | yay -S --needed -

restore_home

echo "==> Services"
sudo systemctl enable $(grep -v '@' "$SRC/lists/systemd-system-enabled.txt" | tr '\n' ' ')
systemctl --user daemon-reload
systemctl --user enable $(cat "$SRC/lists/systemd-user-enabled.txt" | tr '\n' ' ') || true

sudo mkinitcpio -P
echo "Done. Next: run ./install/install.sh, then backup/dell-xps/restore.sh configs, then reboot."
