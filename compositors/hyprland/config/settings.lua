hl.config({
  general = {
    border_size = 0,
    -- Zone-C Frost Workspace artboard: 12px between windows and to the screen edge, 6px under the bar
    gaps_in = 6,
    gaps_out = { top = 6, right = 12, bottom = 12, left = 12 },
    float_gaps = 6,
    resize_on_border = true,
    extend_border_grab_area = 30,
  },

  decoration = {
    rounding = 18,
    active_opacity = 1.0,
    inactive_opacity = 1.0,
    blur = {
      enabled = true,
      -- closer to the design's backdrop-filter: blur(20px) behind the 0.86 terminal and glass panels
      size = 10,
      passes = 3,
      new_optimizations = true,
    },
    shadow = {
      enabled = false,
    },
  },

  input = {
    kb_layout = "us",
    kb_options = "grp:alt_shift_toggle",
    accel_profile = "flat",
    touchpad = {
      natural_scroll = true,
      disable_while_typing = false,
    },
  },

  -- window groups (tabs) in the Frost palette: acc pill for the active tab, surface for the rest
  group = {
    col = {
      border_active = "rgba(9fd3e0ff)",
      border_inactive = "rgba(34424aff)",
      border_locked_active = "rgba(ecdcaaff)",
      border_locked_inactive = "rgba(34424aff)",
    },
    groupbar = {
      font_family = "Geist",
      font_size = 12,
      height = 22,
      gradients = true,
      rounding = 8,
      gradient_rounding = 8,
      gaps_in = 4,
      gaps_out = 4,
      text_color = "rgba(162025ff)",
      text_color_inactive = "rgba(c6d3d9ff)",
      col = {
        active = "rgba(d6e6ecff)",
        inactive = "rgba(2a353bcc)",
        locked_active = "rgba(ecdcaaff)",
        locked_inactive = "rgba(2a353bcc)",
      },
    },
  },

  misc = {
    focus_on_activate = false,
    font_family = "JetBrains Mono",
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
  },
})

-- Motion: ease-out (fast start, soft landing) to open, a quicker ease-in to close. Speed is in
-- tenths of a second. Settings → Trợ năng → "Giảm chuyển động" turns all of it off.
hl.curve("myBezier", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })
hl.curve("zcOut", { type = "bezier", points = { {0.22, 1}, {0.36, 1} } })
hl.curve("zcIn", { type = "bezier", points = { {0.4, 0}, {1, 1} } })
hl.curve("zcMove", { type = "bezier", points = { {0.25, 1}, {0.5, 1} } })

hl.animation({ leaf = "windowsIn", enabled = true, speed = 3.5, bezier = "zcOut", style = "popin 90%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.2, bezier = "zcIn", style = "popin 92%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3.5, bezier = "zcMove" })
-- shell panels, launcher, dialogs: a short pop and fade (the blur behind the glass fades with it)
hl.animation({ leaf = "layersIn", enabled = true, speed = 2.6, bezier = "zcOut", style = "popin 94%" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.8, bezier = "zcIn", style = "popin 96%" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 2.2, bezier = "zcOut" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.6, bezier = "zcIn" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 3, bezier = "zcOut" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2.2, bezier = "zcIn" })
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 3, bezier = "zcOut" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "zcMove", style = "slide" })
hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 3, bezier = "zcOut", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 2.2, bezier = "zcIn", style = "slidevert" })

-- Flameshot: cua so chup phu kin man hinh, khong bi tile / nhet vao nhom tab.
-- Script ~/.local/bin/flameshot-gui bat fullscreen cho no de nam tren ca bar va vien dien.
hl.window_rule({
  name  = "flameshot-fullscreen",
  match = { class = "^(flameshot)$" },

  float        = true,
  move         = "0 0",
  size         = "monitor_w monitor_h",
  no_anim      = true,
  border_size  = 0,
  rounding     = 0,
  stay_focused = true,
})

-- Thanh "... is sharing a window/your screen" cua Chrome: nut Hide cua Chrome xin minimize,
-- Hyprland khong co minimize nen cho no vao special workspace an ngay khi mo.
hl.window_rule({
  name  = "chrome-sharing-indicator",
  match = { class = "^$", title = "^.* is sharing (a window|your screen|a tab|this tab).*$" },

  workspace = "special:sharing silent",
})

-- Hop thoai chon file (portal GTK / KDE, file chooser cua app): portal mo float o 0,0 voi chieu cao
-- gan bang man hinh nen bi bar de len. Ep kich thuoc vua vung lam viec va dat giua man hinh.
hl.window_rule({
  name  = "file-dialog-fit",
  match = { class = "^(xdg-desktop-portal-gtk|Xdg-desktop-portal-gtk|xdg-desktop-portal-kde|org.freedesktop.impl.portal.desktop.kde)$" },

  float  = true,
  size   = "(monitor_w*0.6) (monitor_h*0.75)",
  center = true,
})

-- Zone-C's own apps (Tệp, Giám sát hệ thống, Cửa hàng ứng dụng, Cài đặt) are ordinary windows: they
-- tile like every other app instead of floating over the workspace.

-- Zone-C Frost: frosted glass behind the shell's panels, bar pills and desktop cards (backdrop-filter in
-- the design). ignore_alpha keeps the blur to the glass itself, not the transparent rest of each layer.
-- Layers that are always there (wallpaper, desktop, bar, edges) or animate themselves: no pop.
hl.layer_rule({
  name  = "zone-c-static",
  match = { namespace = "^(wallpaper-bg|qs-desktop|qs-widget-.*|quickshell|qs-sidemusic|qs-electric-border|qs-floating-overlay|zone-c-dim|zone-c-flash|zone-c-draw|qs-screenshot-overlay|assistant-bg|qs-identify|qs-toasts|qs-popups)$" },

  no_anim = true,
})

hl.layer_rule({
  name  = "zone-c-glass",
  match = { namespace = "^(qs-.*)$" },

  blur         = true,
  ignore_alpha = 0.5,
})

-- Desktop cards: their drop shadow (rgba 0,0,0,0.38) already crossed 0.5 here and got frosted into a
-- hard-edged slab under each card; 0.65 still blurs the 0.74 glass but leaves the shadow alone.
hl.layer_rule({
  name  = "zone-c-desktop-glass",
  match = { namespace = "^qs-desktop$" },

  blur         = true,
  ignore_alpha = 0.65,
})
