#!/usr/bin/env bash
# Zone-C installer for a fresh Arch Linux.
#
#   ./install.sh            install packages, link configs, enable services
#   ./install.sh --dry-run  print what would happen, change nothing
#   ./install.sh --yes      don't ask before each step
#   ./install.sh --no-packages   only link configs (packages already installed)
#
# Existing configs are moved to ~/.local/state/zone-c/backup-<time>/ before linking.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dots="$repo/dotfiles"
config="${XDG_CONFIG_HOME:-$HOME/.config}"
cache="${XDG_CACHE_HOME:-$HOME/.cache}/zone-c"
backup="${XDG_STATE_HOME:-$HOME/.local/state}/zone-c/backup-$(date +%Y%m%d-%H%M%S)"

dry=false
yes=false
packages=true
for arg in "$@"; do
    case "$arg" in
    --dry-run) dry=true ;;
    --yes) yes=true ;;
    --no-packages) packages=false ;;
    -h | --help)
        sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
        exit 0
        ;;
    *)
        echo "unknown option: $arg" >&2
        exit 1
        ;;
    esac
done

bold=$'\e[1m' blue=$'\e[34m' green=$'\e[32m' yellow=$'\e[33m' red=$'\e[31m' reset=$'\e[0m'
step() { printf '\n%s==>%s %s%s%s\n' "$blue" "$reset" "$bold" "$*" "$reset"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '    %s!%s %s\n' "$yellow" "$reset" "$*"; }
die() { printf '%serror:%s %s\n' "$red" "$reset" "$*" >&2; exit 1; }

run() {
    if $dry; then
        printf '    %s$%s %s\n' "$green" "$reset" "$*"
    else
        "$@"
    fi
}

ask() {
    $yes && return 0
    $dry && return 0
    local reply
    read -r -p "    $1 [Y/n] " reply
    [[ -z "$reply" || "$reply" =~ ^[Yy] ]]
}

# ── Checks ───────────────────────────────────────────────────────────────
[[ $EUID -ne 0 ]] || die "run as your normal user, not root (sudo is used when needed)"
command -v pacman >/dev/null || die "this installer is for Arch Linux (pacman not found)"

# ── Packages ─────────────────────────────────────────────────────────────
# Each entry is a package, or "a|b" to install the first one the repos have.
official=(
    # Compositor and session
    hyprland hyprpaper hypridle hyprlock hyprpolkitagent
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk qt6-wayland qt5-wayland qt6ct sddm
    # Services the shell reads
    pipewire pipewire-pulse wireplumber networkmanager bluez bluez-utils upower
    power-profiles-daemon brightnessctl playerctl easyeffects
    # Apps and tools used by the keybinds
    kitty zsh zsh-autosuggestions zsh-syntax-highlighting "rofi-wayland|rofi" swaync libnotify
    cliphist wl-clipboard grim slurp thunar firefox neovim git jq
    # Fonts and icons
    ttf-jetbrains-mono ttf-jetbrains-mono-nerd ttf-iosevka-nerd noto-fonts noto-fonts-emoji papirus-icon-theme
)
# Installed from the repos when available, otherwise from the AUR.
either=(quickshell matugen)

in_repos() { pacman -Si "$1" >/dev/null 2>&1; }

install_packages() {
    step "Updating the system and installing packages"
    local repo_pkgs=() aur_pkgs=() entry choice alt
    for entry in "${official[@]}"; do
        choice=""
        IFS='|' read -ra alts <<<"$entry"
        for alt in "${alts[@]}"; do
            if in_repos "$alt"; then
                choice="$alt"
                break
            fi
        done
        if [[ -n "$choice" ]]; then
            repo_pkgs+=("$choice")
        else
            warn "not in the repos, skipped: $entry"
        fi
    done
    for entry in "${either[@]}"; do
        if in_repos "$entry"; then
            repo_pkgs+=("$entry")
        else
            aur_pkgs+=("$entry")
        fi
    done

    info "${#repo_pkgs[@]} packages from the Arch repos"
    run sudo pacman -Syu --needed --noconfirm base-devel "${repo_pkgs[@]}"

    if ((${#aur_pkgs[@]} > 0)); then
        info "from the AUR: ${aur_pkgs[*]}"
        if ! command -v yay >/dev/null && ! command -v paru >/dev/null; then
            info "installing yay"
            local tmp
            tmp="$(mktemp -d)"
            run git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
            if $dry; then
                info "(cd $tmp/yay-bin && makepkg -si --noconfirm)"
            else
                (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
            fi
        fi
        local helper
        helper="$(command -v paru || command -v yay || echo yay)"
        run "$helper" -S --needed --noconfirm "${aur_pkgs[@]}"
    fi
}

# ── Linking ──────────────────────────────────────────────────────────────
# Moves an existing file or directory aside, unless it is already our link.
make_room() {
    local target="$1" source="$2"
    if [[ -L "$target" && "$(readlink -f "$target")" == "$(readlink -f "$source")" ]]; then
        return 1
    fi
    if [[ -e "$target" || -L "$target" ]]; then
        run mkdir -p "$backup"
        run mv "$target" "$backup/"
        info "backed up $(basename "$target") to $backup"
    fi
    return 0
}

link() {
    local source="$1" target="$2"
    run mkdir -p "$(dirname "$target")"
    if make_room "$target" "$source"; then
        run ln -s "$source" "$target"
        info "linked ${target/#$HOME/\~}"
    else
        info "already linked ${target/#$HOME/\~}"
    fi
}

link_configs() {
    step "Linking configs"
    link "$repo" "$config/quickshell/zone-c"
    link "$dots/hypr" "$config/hypr"
    link "$dots/kitty" "$config/kitty"
    link "$dots/rofi" "$config/rofi"
    link "$dots/matugen" "$config/matugen"
    link "$dots/swaync/config.json" "$config/swaync/config.json"
    link "$dots/zsh/.zshrc" "$HOME/.zshrc"
    link "$dots/bin/zone-c-wallpaper" "$HOME/.local/bin/zone-c-wallpaper"

    # swaync needs an absolute path to the colour file, so style.css is rendered.
    if [[ -e "$config/swaync/style.css" && ! -L "$config/swaync/style.css" ]] &&
        ! grep -q "zone-c" "$config/swaync/style.css"; then
        run mkdir -p "$backup"
        run mv "$config/swaync/style.css" "$backup/"
    fi
    if $dry; then
        info "render $config/swaync/style.css"
    else
        sed "s|@HOME@|$HOME|g" "$dots/swaync/style.css" >"$config/swaync/style.css"
    fi

    # Per-machine Hyprland overrides, ignored by git.
    [[ -e "$dots/hypr/local.conf" ]] || run touch "$dots/hypr/local.conf"
}

seed_defaults() {
    step "Default colours and settings"
    run mkdir -p "$cache" "$config/zone-c" "$HOME/Pictures/Wallpapers" "$HOME/Pictures/Screenshots"
    local file
    for file in "$dots"/defaults/*; do
        if [[ -e "$cache/$(basename "$file")" ]]; then
            info "kept ${cache/#$HOME/\~}/$(basename "$file")"
        else
            run cp "$file" "$cache/"
        fi
    done

    if [[ -e "$config/zone-c/shell.json" ]]; then
        info "kept ~/.config/zone-c/shell.json"
    elif $dry; then
        info "create ~/.config/zone-c/shell.json (matugen colours on)"
    else
        sed 's/"matugen": false/"matugen": true/' "$repo/config/shell.example.json" >"$config/zone-c/shell.json"
        info "created ~/.config/zone-c/shell.json"
    fi
}

enable_services() {
    step "Enabling services"
    run sudo systemctl enable --now NetworkManager.service bluetooth.service power-profiles-daemon.service
    if systemctl list-unit-files display-manager.service >/dev/null 2>&1 &&
        systemctl is-enabled display-manager.service >/dev/null 2>&1; then
        info "a display manager is already enabled, SDDM left alone"
    elif ask "Enable SDDM as the login screen?"; then
        run sudo systemctl enable sddm.service
    fi
}

set_shell() {
    local zsh_path
    zsh_path="$(command -v zsh || echo /usr/bin/zsh)"
    [[ "${SHELL:-}" == "$zsh_path" ]] && return
    step "Login shell"
    if ask "Use zsh as your login shell?"; then
        run chsh -s "$zsh_path"
    fi
}

# ── Main ─────────────────────────────────────────────────────────────────
printf '%sZone-C installer%s  (%s)\n' "$bold" "$reset" "$repo"
$dry && warn "dry run: nothing will be changed"

if $packages; then
    ask "Install packages with pacman (and the AUR when needed)?" && install_packages
fi
ask "Link configs into ~/.config (existing ones are backed up)?" && link_configs
seed_defaults
if $packages; then
    enable_services
    set_shell
fi

step "Done"
info "Log out and pick the Hyprland session (or reboot)."
info "Put wallpapers in ~/Pictures/Wallpapers, then press SUPER+W to pick one;"
info "the bar, popups, borders, kitty, rofi and swaync take its colours."
info "Shell logs: run 'qs -c zone-c' from a terminal."
