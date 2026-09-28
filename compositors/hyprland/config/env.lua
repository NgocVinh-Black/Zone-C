hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Fcitx5 (Vietnamese input - Unikey)
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("QT_IM_MODULE", "fcitx")
hl.env("SDL_IM_MODULE", "fcitx")

-- Qt icon theme (Papirus-Dark qua qt6ct) - sua icon o den hong trong shell
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QS_ICON_THEME", "Papirus-Dark")
