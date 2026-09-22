# Zone-C — bash login shell (used when zsh was not chosen as the login shell).
# SDDM sources this when starting the Hyprland session, so the zone-c command
# is on PATH for the whole session.
export PATH="$HOME/.local/bin:$PATH"

[[ -f ~/.bashrc ]] && . ~/.bashrc
