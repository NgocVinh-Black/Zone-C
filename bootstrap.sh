#!/usr/bin/env bash
# Zone-C bootstrap: one command from a fresh Arch TTY to an installed desktop.
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/NgocVinh-Black/Zone-C/main/bootstrap.sh)
#   bash <(curl -fsSL ...) --yes        pass any install.sh option through
#
# Installs git, clones the repo into ~/Projects/Zone-C, then runs install.sh.
# Already cloned? It pulls and re-runs the installer instead.
#
#   ZONE_C_DIR=~/src/zone-c   clone somewhere else
#   ZONE_C_BRANCH=develop     use another branch
set -euo pipefail

repo_url="${ZONE_C_REPO:-https://github.com/NgocVinh-Black/Zone-C.git}"
dir="${ZONE_C_DIR:-$HOME/Projects/Zone-C}"
branch="${ZONE_C_BRANCH:-main}"

bold=$'\e[1m' blue=$'\e[34m' red=$'\e[31m' reset=$'\e[0m'
step() { printf '\n%s==>%s %s%s%s\n' "$blue" "$reset" "$bold" "$*" "$reset"; }
die() { printf '%serror:%s %s\n' "$red" "$reset" "$*" >&2; exit 1; }

[[ $EUID -ne 0 ]] || die "run as your normal user, not root (sudo is used when needed)"
command -v pacman >/dev/null || die "this bootstrap is for Arch Linux (pacman not found)"
command -v sudo >/dev/null || die "sudo is not installed; install it and add your user to the wheel group first"

if ! command -v git >/dev/null; then
    step "Installing git"
    sudo pacman -Syu --needed --noconfirm git
fi

if [[ -d "$dir/.git" ]]; then
    step "Updating $dir"
    git -C "$dir" pull --ff-only
else
    step "Cloning Zone-C into $dir"
    mkdir -p "$(dirname "$dir")"
    git clone --branch "$branch" "$repo_url" "$dir"
fi

step "Running the installer"
exec "$dir/install.sh" "$@"
