#!/usr/bin/env bash

EXTRA_CONFIGS=(
    "kitty"
    "cava"
    "fastfetch"
    "fcitx5"
    "qt6ct"
    "foot"
    "systemd"
    "mimeapps.list"
    "code-flags.conf"
)

# mimeapps.list is shared with other programs (Claude Code, browsers add their own handlers):
# take the repo's entries, but keep every entry the user has that the repo does not set.
merge_mimeapps() {
    local src="$1" dest="$2"
    if [ ! -f "$dest" ] || ! command -v python3 >/dev/null 2>&1; then
        cp "$src" "$dest"
        return
    fi
    python3 - "$src" "$dest" <<'PY' || cp "$src" "$dest"
import configparser, sys
def load(p):
    c = configparser.ConfigParser(interpolation=None, strict=False)
    c.optionxform = str
    c.read(p, encoding="utf-8")
    return c
repo, mine = load(sys.argv[1]), load(sys.argv[2])
for sec in mine.sections():
    if not repo.has_section(sec):
        repo.add_section(sec)
    for key, val in mine.items(sec):
        if not repo.has_option(sec, key):
            repo.set(sec, key, val)
with open(sys.argv[2], "w", encoding="utf-8") as f:
    repo.write(f, space_around_delimiters=False)
PY
}

# copies one shipped config file into ~/.config, merging the ones that are shared
install_config_file() {
    local src="$1" dest="$2"
    mkdir -p "$(dirname "$dest")"
    if [ "$(basename "$dest")" = "mimeapps.list" ]; then
        merge_mimeapps "$src" "$dest"
    else
        cp "$src" "$dest"
    fi
}

render_wallpaper_progress() {
    local current="$1"
    local total="$2"
    local label="${3:-Installing wallpapers}"
    local bar_width=30
    local percent=0
    if [ "$total" -gt 0 ]; then
        percent=$(( current * 100 / total ))
    fi
    local filled=0
    if [ "$total" -gt 0 ]; then
        filled=$(( current * bar_width / total ))
    fi
    local empty=$(( bar_width - filled ))
    local bar_fill=""
    local bar_empty=""
    if [ "$filled" -gt 0 ]; then
        bar_fill=$(printf "%*s" "$filled" "" | tr ' ' '=')
    fi
    if [ "$empty" -gt 0 ]; then
        bar_empty=$(printf "%*s" "$empty" "" | tr ' ' ' ')
    fi
    printf "\r\e[36m[ INFO ]\e[0m %s \e[32m[%s%s]\e[0m %3d%% (%d/%d)" "$label" "$bar_fill" "$bar_empty" "$percent" "$current" "$total"
}

get_wallpaper_dir() {
    local user_pics=""
    if [ -f "$HOME/.config/user-dirs.dirs" ]; then
        user_pics=$(grep '^XDG_PICTURES_DIR' "$HOME/.config/user-dirs.dirs" 2>/dev/null | cut -d= -f2 | tr -d '"' | sed "s|\$HOME|$HOME|g")
    fi
    if [[ -z "$user_pics" || "$user_pics" == "$HOME" ]]; then
        if command -v xdg-user-dir &>/dev/null; then
            user_pics="$(xdg-user-dir PICTURES 2>/dev/null || true)"
        fi
    fi
    if [[ -z "$user_pics" || "$user_pics" == "$HOME" ]]; then
        user_pics="$HOME/Pictures"
    fi
    user_pics="${user_pics%/}"
    echo "$user_pics/Wallpapers"
}

install_wallpapers() {
    local full_pack="${1:-true}"
    local wallpaper_dir
    wallpaper_dir=$(get_wallpaper_dir)
    local wallpaper_repo="https://github.com/ilyamiro/shell-wallpapers.git"
    local clone_dir="${XDG_CACHE_HOME:-"$HOME/.cache"}/zone-c-wallpapers"

    mkdir -p "$wallpaper_dir"

    if [ -n "$PROJECT_ROOT" ] && [ -d "$PROJECT_ROOT/src/assets/wallpapers" ]; then
        cp -f "$PROJECT_ROOT/src/assets/wallpapers/"* "$wallpaper_dir/" 2>/dev/null || true
    fi

    local sync_success=false
    if [ -d "$clone_dir/.git" ]; then
        if git -C "$clone_dir" fetch --depth 1 origin 2>/dev/null; then
            if git -C "$clone_dir" reset --hard FETCH_HEAD 2>/dev/null || \
               git -C "$clone_dir" reset --hard origin/HEAD 2>/dev/null || \
               git -C "$clone_dir" reset --hard origin/main 2>/dev/null || \
               git -C "$clone_dir" reset --hard origin/master 2>/dev/null; then
                sync_success=true
            fi
        fi
    fi

    if [ "$sync_success" != true ]; then
        rm -rf "$clone_dir"
        echo -e "\n\e[36m[ INFO ]\e[0m Cloning wallpapers repository..."
        git clone --depth 1 "$wallpaper_repo" "$clone_dir" 2>/dev/null || true
    fi

    local src_dir="$clone_dir"
    if [ -d "$clone_dir/images" ]; then
        src_dir="$clone_dir/images"
    fi

    if [ ! -d "$src_dir" ]; then
        return 0
    fi

    if [ "$full_pack" = true ]; then
        local files=()
        while IFS= read -r f; do
            [[ -n "$f" ]] && files+=("$f")
        done < <(find "$src_dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.webp" \) 2>/dev/null)

        local total=${#files[@]}
        local count=0

        if [ "$total" -gt 0 ]; then
            for file in "${files[@]}"; do
                cp "$file" "$wallpaper_dir/" 2>/dev/null || true
                count=$((count + 1))
                render_wallpaper_progress "$count" "$total" "Installing wallpapers"
            done
            echo ""
        else
            find "$src_dir" -type f ! -name "README.md" ! -name "LICENSE" ! -path "*/.git/*" -exec cp {} "$wallpaper_dir/" \; 2>/dev/null || true
        fi
    else
        if [ -z "$(ls -A "$wallpaper_dir" 2>/dev/null | grep -iE '\.(jpg|jpeg|png|gif|webp)$')" ]; then
            local random_pics=()
            while IFS= read -r pic; do
                [[ -n "$pic" ]] && random_pics+=("$pic")
            done < <(find "$src_dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.webp" \) 2>/dev/null | shuf -n 3)

            local total=${#random_pics[@]}
            local count=0

            if [ "$total" -gt 0 ]; then
                for pic in "${random_pics[@]}"; do
                    cp "$pic" "$wallpaper_dir/" 2>/dev/null || true
                    count=$((count + 1))
                    render_wallpaper_progress "$count" "$total" "Installing wallpapers"
                done
                echo ""
            fi
        fi
    fi
}

setup_sddm() {
    local project_root="$1"
    local install_state="${2:-$INSTALL_STATE}"
    local is_reinstall="${3:-$IS_REINSTALL}"

    if [ "$OPT_SDDM" != true ]; then
        return 0
    fi

    local is_update=false
    if [[ "$install_state" == "current" && "$is_reinstall" != "true" ]]; then
        is_update=true
    fi

    local init_sys="generic"
    if declare -f detect_init_system >/dev/null; then
        init_sys=$(detect_init_system)
    fi

    echo -e "\n\e[36m[ INFO ]\e[0m $(t "installer.deploy.configuring_sddm")"

    if [ "$is_update" != true ] && [ "$REPLACE_DM" = true ]; then
        local dms=("gdm" "gdm3" "lightdm" "lxdm" "lxdm-gtk3" "ly" "greetd" "emptty")
        for dm in "${dms[@]}"; do
            if declare -f disable_system_service >/dev/null; then
                disable_system_service "$dm" "$init_sys"
            fi
            if command -v pacman &>/dev/null; then
                if pacman -Qq "$dm" &>/dev/null; then
                    echo "  $(t "installer.deploy.disabling_dm" "dm=$dm")"
                    sudo pacman -Rns --noconfirm "$dm" >/dev/null 2>&1 || true
                fi
            fi
        done
    fi

    sudo rm -rf /usr/share/sddm/themes/matugen-minimal
    sudo rm -rf /usr/share/sddm/themes/material-you
    sudo rm -f /etc/sddm.conf.d/*matugen*.conf
    sudo rm -f /etc/sddm.conf.d/*material-you*.conf
    # older installs pinned zone-thunder in a later-sorting file, which overrides the default below
    sudo rm -f /etc/sddm.conf.d/20-zone-thunder.conf

    if [ "$is_update" != true ] && [ -f /etc/sddm.conf ]; then
        sudo cp -a /etc/sddm.conf "/etc/sddm.conf.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
        sudo rm -f /etc/sddm.conf
    fi

    # zone-frost (the Frost design, default) and zone-thunder; current/ belongs to the user so the
    # shell can sync the active wallpaper and colours into it (scripts/sddm_sync.sh). QML stays root's.
    local theme_name
    for theme_name in zone-frost zone-thunder; do
        local sddm_theme_src="$project_root/config/sddm/themes/$theme_name"
        local sddm_theme_dest="/usr/share/sddm/themes/$theme_name"
        [ -d "$sddm_theme_src" ] || continue
        sudo mkdir -p "$sddm_theme_dest"
        sudo cp -r "$sddm_theme_src/." "$sddm_theme_dest/"
        sudo chmod -R 755 "$sddm_theme_dest"
        sudo install -d -o "$USER" -g "$(id -gn)" -m 755 "$sddm_theme_dest/current"
        if [ -d "$sddm_theme_src/font" ]; then
            sudo mkdir -p /usr/share/fonts/TTF
            sudo cp -r "$sddm_theme_src/font/"*.ttf /usr/share/fonts/TTF/ 2>/dev/null || true
        fi
    done
    fc-cache -f /usr/share/fonts >/dev/null 2>&1 || true

    sudo mkdir -p /etc/sddm.conf.d

    # QML_XHR_ALLOW_FILE_READ lets zone-frost read the battery level from /sys
    if [ "$SDDM_WAYLAND" = true ]; then
        cat <<EOF | sudo tee /etc/sddm.conf.d/10-material-you.conf > /dev/null
[Theme]
Current=zone-frost
ThemeDir=/usr/share/sddm/themes

[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_DISABLE_WINDOWDECORATION=1,QML_XHR_ALLOW_FILE_READ=1
InputMethod=
EOF
    else
        cat <<EOF | sudo tee /etc/sddm.conf.d/10-material-you.conf > /dev/null
[Theme]
Current=zone-frost
ThemeDir=/usr/share/sddm/themes

[General]
GreeterEnvironment=QML_XHR_ALLOW_FILE_READ=1
InputMethod=
EOF
    fi

    if declare -f enable_system_service >/dev/null; then
        enable_system_service "sddm" "$init_sys"
    else
        case "$init_sys" in
            systemd)
                sudo systemctl enable --now sddm.service 2>/dev/null || sudo systemctl enable -f sddm.service 2>/dev/null || sudo systemctl enable sddm 2>/dev/null || true
                ;;
            openrc)
                sudo rc-update add sddm default 2>/dev/null || true
                sudo rc-service sddm start 2>/dev/null || true
                ;;
            dinit)
                sudo dinitctl enable sddm 2>/dev/null || sudo dinitctl start sddm 2>/dev/null || true
                ;;
            runit)
                if [ -d "/etc/sv/sddm" ]; then
                    sudo ln -sf "/etc/sv/sddm" /var/service/ 2>/dev/null || true
                fi
                ;;
            s6)
                sudo s6-rc-bundle-update -b add default sddm 2>/dev/null || true
                ;;
            *)
                sudo systemctl enable sddm.service -f 2>/dev/null || true
                ;;
        esac
    fi

    echo -e "  \e[32m$(t "installer.deploy.sddm_success")\e[0m"
}

# float-cat: bot AI noi tren man hinh khi Claude Code chay (config/float-cat -> ~/.local/share/float-cat).
# Chay ca khi cai day du lan cap nhat. Mau lay truc tiep tu theme Frost;
# vi tri bot (~/.local/state/float-cat) giu nguyen.
deploy_float_cat() {
    local REPO_ROOT="$1"
    local BIN_DIR="$2"
    local src="$REPO_ROOT/config/float-cat"
    local dest="$HOME/.local/share/float-cat"

    [ -d "$src" ] || return 0
    mkdir -p "$dest" "$HOME/.local/state/float-cat" "$BIN_DIR"
    cp -r "$src/." "$dest/"
    # the cat's picture layers and tinting are gone: the bot is drawn in QML
    rm -rf "$dest/gray" "$dest/src" "$dest/themed" "$dest/cat.svg"

    if [ -f "$REPO_ROOT/config/local-bin/float-cat" ]; then
        cp "$REPO_ROOT/config/local-bin/float-cat" "$BIN_DIR/float-cat"
        chmod +x "$BIN_DIR/float-cat"
    fi
}

# profile/: the owner's own setup (settings without IP or location, desktop widget layout, saved
# theme presets, avatar, active wallpaper) so a fresh install looks like the original machine.
# Only on a fresh install or reinstall; a normal update keeps whatever the user has changed since.
# Runs before init_zone_c_config, which merges the template in and detects the location anew.
apply_profile() {
    local REPO_ROOT="$1"
    local install_state="$2"
    local is_reinstall="$3"
    local wallpaper_dir="$4"
    local src="$REPO_ROOT/profile"

    [ -d "$src" ] || return 0
    [[ "$install_state" == "current" && "$is_reinstall" != "true" ]] && return 0

    local config_dir="$HOME/.config/zone-c"
    local state_dir="$HOME/.local/state/zone-c"
    local wp_cache="${XDG_CACHE_HOME:-"$HOME/.cache"}/zone-c/wallpaper"
    mkdir -p "$config_dir" "$state_dir"

    if [ -f "$src/settings.json" ]; then
        local merged
        merged=$(sed "s|@HOME@|$HOME|g" "$src/settings.json" | jq -s '(.[1] // {}) * .[0]' - "$config_dir/settings.json" 2>/dev/null) \
            || merged=$(sed "s|@HOME@|$HOME|g" "$src/settings.json")
        echo "$merged" > "$config_dir/settings.json"
    fi
    [ -d "$src/state" ] && cp -r "$src/state/." "$state_dir/"
    [ -f "$src/face.png" ] && cp -f "$src/face.png" "$HOME/.face"

    # the wallpaper comes from the downloaded pack; the shell restores it from current_<monitor>,
    # and the profile (like the widget layout in state/desktop) is for the laptop panel eDP-1
    local wp_name
    wp_name=$(head -n 1 "$src/wallpaper.txt" 2>/dev/null)
    if [ -n "$wp_name" ] && [ -f "$wallpaper_dir/$wp_name" ]; then
        mkdir -p "$wp_cache"
        printf '%s\n' "$wallpaper_dir/$wp_name" > "$wp_cache/current_eDP-1"
        printf '%s\n' "$wp_name" > "$wp_cache/current_eDP-1_name"
    fi
}

deploy_package() {
    local REPO_ROOT="$1"
    local OLD_COMMIT="$2"
    local NEW_COMMIT="$3"
    local IS_REINSTALL="$4"
    local INSTALL_STATE="$5"
    shift 5
    local COMPOSITORS=("$@")

    local TARGET_BASE="$HOME/.local/share/zone-c"
    local BIN_DIR="$HOME/.local/bin"

    local is_update=false
    if [[ "$INSTALL_STATE" == "current" && "$IS_REINSTALL" != "true" ]]; then
        is_update=true
    fi

    local do_full_deploy=true

    if [ "$IS_REINSTALL" != "true" ] && [ -n "$OLD_COMMIT" ] && [ "$OLD_COMMIT" != "unknown" ] && [ -d "$REPO_ROOT/.git" ]; then
        if git -C "$REPO_ROOT" cat-file -e "$OLD_COMMIT" 2>/dev/null; then
            do_full_deploy=false
        fi
    fi

    if [ "$do_full_deploy" = true ]; then
        rm -rf "$TARGET_BASE"
        mkdir -p "$TARGET_BASE/bin" "$TARGET_BASE/src" "$BIN_DIR"

        if [ -d "$REPO_ROOT/bin" ] && [ "$(ls -A "$REPO_ROOT/bin" 2>/dev/null)" ]; then
            cp -r "$REPO_ROOT/bin/." "$TARGET_BASE/bin/"
            chmod +x "$TARGET_BASE/bin/"* 2>/dev/null || true
        fi

        if [ -d "$REPO_ROOT/src" ] && [ "$(ls -A "$REPO_ROOT/src" 2>/dev/null)" ]; then
            cp -r "$REPO_ROOT/src/." "$TARGET_BASE/src/"
            find "$TARGET_BASE/src/scripts" -type f -name "*.sh" -exec chmod +x {} + 2>/dev/null || true
        fi

        if [ "$is_update" != "true" ]; then
            for cfg in "${EXTRA_CONFIGS[@]}"; do
                local src_cfg="$REPO_ROOT/config/$cfg"
                local dest_cfg="$HOME/.config/$cfg"
                if [ -d "$src_cfg" ]; then
                    mkdir -p "$dest_cfg"
                    cp -r "$src_cfg/." "$dest_cfg/"
                elif [ -f "$src_cfg" ]; then
                    install_config_file "$src_cfg" "$dest_cfg"
                fi
            done
        fi

        if [ -d "$REPO_ROOT/config/local-bin" ]; then
            cp -r "$REPO_ROOT/config/local-bin/." "$BIN_DIR/"
            for f in "$REPO_ROOT/config/local-bin/"*; do
                chmod +x "$BIN_DIR/$(basename "$f")" 2>/dev/null || true
            done
        fi

        if [ -d "$REPO_ROOT/config/icons" ]; then
            mkdir -p "$HOME/.local/share/icons/hicolor/scalable/apps"
            cp -r "$REPO_ROOT/config/icons/." "$HOME/.local/share/icons/hicolor/scalable/apps/"
        fi

        # Zone-C file chooser for xdg-desktop-portal (the .portal file lives in the system data dir)
        if [ -d "$REPO_ROOT/config/portal" ]; then
            local zsrc="$HOME/.local/share/zone-c/src"
            mkdir -p "$HOME/.local/share/dbus-1/services" "$HOME/.config/xdg-desktop-portal"
            sed "s|@ZONEC_SRC@|$zsrc|" "$REPO_ROOT/config/portal/org.freedesktop.impl.portal.desktop.zonec.service" \
                > "$HOME/.local/share/dbus-1/services/org.freedesktop.impl.portal.desktop.zonec.service"
            cp "$REPO_ROOT/config/portal/hyprland-portals.conf" "$HOME/.config/xdg-desktop-portal/hyprland-portals.conf"
            sudo install -Dm644 "$REPO_ROOT/config/portal/zonec.portal" /usr/share/xdg-desktop-portal/portals/zonec.portal 2>/dev/null || true
            # screen-share picker of xdg-desktop-portal-hyprland
            mkdir -p "$HOME/.config/hypr"
            sed "s|@BIN_DIR@|$BIN_DIR|" "$REPO_ROOT/config/portal/xdph.conf" > "$HOME/.config/hypr/xdph.conf"
        fi

        if [ -d "$REPO_ROOT/config/applications" ]; then
            mkdir -p "$HOME/.local/share/applications"
            cp -r "$REPO_ROOT/config/applications/." "$HOME/.local/share/applications/"
            update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
        fi

        local bashrc="$HOME/.bashrc"
        if [ -f "$BIN_DIR/zonec-banner" ] && ! grep -q 'zonec-banner' "$bashrc" 2>/dev/null; then
            {
                echo ''
                echo '# Zone-C: banner + fastfetch khi mo terminal'
                echo 'if [[ $- == *i* ]]; then'
                echo '    "$HOME/.local/bin/zonec-banner"'
                echo '    command -v fastfetch >/dev/null && fastfetch'
                echo 'fi'
            } >> "$bashrc"
        fi

        # ~/.local/bin vao PATH de goi duoc cac lenh Zone-C (chup, lam-min, usb-list...) tu terminal
        # prompt and colours of the current Zone-C theme (scripts/term_sync.sh): after the distro's own PS1
        # but before the banner and ble-attach (ble.sh keeps the PS1 it attached with), moving an older line
        python3 - "$bashrc" <<'PYBASHRC'
import sys
p = sys.argv[1]
line = '[[ $- == *i* && -f ${XDG_STATE_HOME:-$HOME/.local/state}/zone-c/term_theme.sh ]] && source "${XDG_STATE_HOME:-$HOME/.local/state}/zone-c/term_theme.sh"'
try:
    rows = open(p).read().split("\n")
except FileNotFoundError:
    rows = []
rows = [r for r in rows if "zone-c/term_theme.sh" not in r and r != "# Zone-C: dau nhac lenh + mau theo theme dang dung"]
at = next((i for i, r in enumerate(rows) if r.strip().startswith(("zonec-banner", "fastfetch")) or "ble-attach" in r), None)
if at is not None:
    while at > 0 and rows[at - 1].lstrip().startswith("#"):   # keep a block's comment with it
        at -= 1
    rows[at:at] = ["# Zone-C: dau nhac lenh + mau theo theme dang dung", line, ""]
else:
    rows += ["", "# Zone-C: dau nhac lenh + mau theo theme dang dung", line]
open(p, "w").write("\n".join(rows))
PYBASHRC

        if ! grep -q 'PATH=.*\.local/bin' "$bashrc" 2>/dev/null; then
            {
                echo ''
                echo '# Zone-C: lenh trong ~/.local/bin'
                echo 'export PATH="$HOME/.local/bin:$PATH"'
            } >> "$bashrc"
        fi

        # ble.sh: goi y lenh cu tu lich su (autosuggestion) cho bash
        local blesh_dir="$HOME/.local/share/blesh"
        if [ ! -f "$blesh_dir/ble.sh" ]; then
            local blesh_src
            blesh_src=$(mktemp -d)
            if git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git "$blesh_src/ble.sh" >/dev/null 2>&1; then
                make -C "$blesh_src/ble.sh" install PREFIX="$HOME/.local" >/dev/null 2>&1 || true
            fi
            rm -rf "$blesh_src"
        fi
        if [ -f "$REPO_ROOT/config/blesh/blerc" ]; then
            cp "$REPO_ROOT/config/blesh/blerc" "$HOME/.blerc"
        fi
        if [ -f "$blesh_dir/ble.sh" ] && ! grep -q 'blesh/ble.sh' "$bashrc" 2>/dev/null; then
            local bashrc_tmp
            bashrc_tmp=$(mktemp)
            {
                echo '# Zone-C: ble.sh - goi y lenh cu tu lich su (de o dau file)'
                echo '[[ $- == *i* && -f ~/.local/share/blesh/ble.sh ]] && source -- ~/.local/share/blesh/ble.sh --attach=none'
                echo ''
                echo '# Zone-C: lich su lenh - luu nhieu, khong trung, ghi ngay'
                echo 'HISTSIZE=50000'
                echo 'HISTFILESIZE=100000'
                echo 'HISTCONTROL=ignoreboth:erasedups'
                echo 'shopt -s histappend'
                echo 'PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"'
                echo ''
                [ -f "$bashrc" ] && cat "$bashrc"
                echo ''
                echo '# Zone-C: gan ble.sh (de o cuoi file)'
                echo '[[ ${BLE_VERSION-} ]] && ble-attach'
            } > "$bashrc_tmp"
            mv "$bashrc_tmp" "$bashrc"
        fi

        # Zone-C: panel Bluetooth tu lam agent ghep doi, tat agent cua blueman de khong tranh nhau
        if command -v gsettings >/dev/null 2>&1; then
            gsettings set org.blueman.general plugin-list "['!AuthAgent']" 2>/dev/null || true
            gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
        fi

        if [ "$is_update" != "true" ]; then
            for comp in "${COMPOSITORS[@]}"; do
                local target_config_name
                case "$comp" in
                    hyprland) target_config_name="hypr" ;;
                    niri) target_config_name="niri" ;;
                    sway) target_config_name="sway" ;;
                    *) target_config_name="$comp" ;;
                esac

                local TARGET_CONFIG_DIR="$HOME/.config/$target_config_name"
                local BACKUP_BASE="$HOME/.config/${target_config_name}_backup"
                local BACKUP_DIR="$BACKUP_BASE/backup_$(date +%Y%m%d_%H%M%S)"

                local SRC_COMP_DIR=""
                if [ -d "$REPO_ROOT/compositors/$comp" ] && [ "$(ls -A "$REPO_ROOT/compositors/$comp" 2>/dev/null)" ]; then
                    SRC_COMP_DIR="$REPO_ROOT/compositors/$comp"
                elif [ -d "$REPO_ROOT/compositor/$comp" ] && [ "$(ls -A "$REPO_ROOT/compositor/$comp" 2>/dev/null)" ]; then
                    SRC_COMP_DIR="$REPO_ROOT/compositor/$comp"
                fi

                if [ -n "$SRC_COMP_DIR" ]; then
                    if [ -d "$TARGET_CONFIG_DIR" ] && [ "$(ls -A "$TARGET_CONFIG_DIR" 2>/dev/null)" ]; then
                        mkdir -p "$BACKUP_DIR"
                        cp -a "$TARGET_CONFIG_DIR/." "$BACKUP_DIR/" 2>/dev/null || true
                    fi

                    mkdir -p "$TARGET_CONFIG_DIR"
                    cp -r "$SRC_COMP_DIR/." "$TARGET_CONFIG_DIR/"

                    find "$TARGET_CONFIG_DIR" -type f -o -type l | while IFS= read -r dest_file; do
                        local rel_path="${dest_file#$TARGET_CONFIG_DIR/}"
                        if [ ! -e "$SRC_COMP_DIR/$rel_path" ] && [ ! -L "$SRC_COMP_DIR/$rel_path" ]; then
                            rm -f "$dest_file"
                        fi
                    done

                    find "$TARGET_CONFIG_DIR" -depth -type d -empty ! -path "$TARGET_CONFIG_DIR" -delete 2>/dev/null || true
                fi
            done
        fi
    else
        mkdir -p "$TARGET_BASE/bin" "$TARGET_BASE/src" "$BIN_DIR"

        local changed_files=""
        local deleted_files=""

        if [ "$OLD_COMMIT" != "$NEW_COMMIT" ]; then
            changed_files=$(git -C "$REPO_ROOT" diff --name-only --no-renames --diff-filter=AM "$OLD_COMMIT" "$NEW_COMMIT" 2>/dev/null || true)
            deleted_files=$(git -C "$REPO_ROOT" diff --name-only --no-renames --diff-filter=D "$OLD_COMMIT" "$NEW_COMMIT" 2>/dev/null || true)
        fi

        if [ -n "$deleted_files" ]; then
            while IFS= read -r file; do
                [[ -z "$file" ]] && continue
                if [[ "$file" == bin/* ]]; then
                    rm -f "$TARGET_BASE/$file"
                elif [[ "$file" == src/* ]]; then
                    rm -f "$TARGET_BASE/$file"
                elif [[ "$file" == config/* ]]; then
                    if [ "$is_update" != "true" ]; then
                        local rel_cfg="${file#config/}"
                        local cfg_name="${rel_cfg%%/*}"
                        for cfg in "${EXTRA_CONFIGS[@]}"; do
                            if [[ "$cfg" == "$cfg_name" ]]; then
                                rm -f "$HOME/.config/$rel_cfg"
                            fi
                        done
                    fi
                elif [[ "$file" == compositors/* || "$file" == compositor/* ]]; then
                    if [ "$is_update" != "true" ]; then
                        local comp_part="${file#compositor*/}"
                        local comp_name="${comp_part%%/*}"
                        local comp_file="${comp_part#*/}"
                        for comp in "${COMPOSITORS[@]}"; do
                            if [[ "$comp" == "$comp_name" ]]; then
                                local target_config_name
                                case "$comp" in
                                    hyprland) target_config_name="hypr" ;;
                                    niri) target_config_name="niri" ;;
                                    sway) target_config_name="sway" ;;
                                    *) target_config_name="$comp" ;;
                                esac
                                rm -f "$HOME/.config/$target_config_name/$comp_file"
                            fi
                        done
                    fi
                fi
            done <<< "$deleted_files"
        fi

        if [ -n "$changed_files" ]; then
            while IFS= read -r file; do
                [[ -z "$file" ]] && continue
                if [[ "$file" == bin/* ]]; then
                    mkdir -p "$(dirname "$TARGET_BASE/$file")"
                    cp "$REPO_ROOT/$file" "$TARGET_BASE/$file"
                    chmod +x "$TARGET_BASE/$file" 2>/dev/null || true
                elif [[ "$file" == src/* ]]; then
                    mkdir -p "$(dirname "$TARGET_BASE/$file")"
                    cp "$REPO_ROOT/$file" "$TARGET_BASE/$file"
                    if [[ "$file" == *.sh ]]; then
                        chmod +x "$TARGET_BASE/$file" 2>/dev/null || true
                    fi
                elif [[ "$file" == config/* ]]; then
                    if [ "$is_update" != "true" ]; then
                        local rel_cfg="${file#config/}"
                        local cfg_name="${rel_cfg%%/*}"
                        for cfg in "${EXTRA_CONFIGS[@]}"; do
                            if [[ "$cfg" == "$cfg_name" ]]; then
                                install_config_file "$REPO_ROOT/$file" "$HOME/.config/$rel_cfg"
                            fi
                        done
                    fi
                elif [[ "$file" == compositors/* || "$file" == compositor/* ]]; then
                    if [ "$is_update" != "true" ]; then
                        local comp_part="${file#compositor*/}"
                        local comp_name="${comp_part%%/*}"
                        local comp_file="${comp_part#*/}"
                        for comp in "${COMPOSITORS[@]}"; do
                            if [[ "$comp" == "$comp_name" ]]; then
                                local target_config_name
                                case "$comp" in
                                    hyprland) target_config_name="hypr" ;;
                                    niri) target_config_name="niri" ;;
                                    sway) target_config_name="sway" ;;
                                    *) target_config_name="$comp" ;;
                                esac
                                mkdir -p "$(dirname "$HOME/.config/$target_config_name/$comp_file")"
                                cp "$REPO_ROOT/$file" "$HOME/.config/$target_config_name/$comp_file"
                            fi
                        done
                    fi
                fi
            done <<< "$changed_files"
        fi
    fi

    deploy_float_cat "$REPO_ROOT" "$BIN_DIR"

    if [ -f "$TARGET_BASE/bin/zone-c" ]; then
        ln -sf "$TARGET_BASE/bin/zone-c" "$BIN_DIR/zone-c"
        sudo ln -sf "$TARGET_BASE/bin/zone-c" /usr/local/bin/zone-c 2>/dev/null || true
    fi

    if [ -f "$TARGET_BASE/bin/zone-cd" ]; then
        ln -sf "$TARGET_BASE/bin/zone-cd" "$BIN_DIR/zone-cd"
        sudo ln -sf "$TARGET_BASE/bin/zone-cd" /usr/local/bin/zone-cd 2>/dev/null || true
    fi
}
