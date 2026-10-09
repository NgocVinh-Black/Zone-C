hl.config({
  general = {
    border_size = 0,
    gaps_in = 4,
    gaps_out = 6,
    float_gaps = 6,
    resize_on_border = true,
    extend_border_grab_area = 30,
  },

  decoration = {
    rounding = 12,
    active_opacity = 1.0,
    inactive_opacity = 1.0,
    blur = {
      enabled = true,
      size = 8,
      passes = 2,
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

  misc = {
    focus_on_activate = false,
    font_family = "JetBrains Mono",
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
  },
})

hl.curve("myBezier", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })

hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "myBezier", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 5, bezier = "myBezier", style = "popin 80%" })
hl.animation({ leaf = "layers", enabled = true, speed = 5, bezier = "myBezier", style = "fade" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 5, bezier = "myBezier", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 5, bezier = "myBezier", style = "fade" })
hl.animation({ leaf = "fade", enabled = true, speed = 5, bezier = "myBezier" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "myBezier", style = "slide" })
hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 5, bezier = "myBezier", style = "fade" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 5, bezier = "myBezier", style = "fade" })

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
