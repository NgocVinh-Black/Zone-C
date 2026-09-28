hl.config({
  general = {
    border_size = 3,
    -- Vien dien (electric) cho cua so dang chon, chay vong quanh nho animation borderangle
    col = {
      active_border = { colors = { "rgba(8fe3ffff)", "rgba(1e6fffff)", "rgba(ffffffff)", "rgba(1e6fffff)", "rgba(8fe3ffff)" }, angle = 45 },
      inactive_border = "rgba(00000000)",
    },
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
    -- Phat sang xanh quanh cua so dang chon
    shadow = {
      enabled = true,
      range = 18,
      render_power = 3,
      color = "rgba(1e8fffcc)",
      color_inactive = "rgba(00000000)",
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

-- Vien dien chay vong lien tuc
hl.curve("zcLinear", { type = "bezier", points = { {0, 0}, {1, 1} } })
hl.animation({ leaf = "borderangle", enabled = true, speed = 20, bezier = "zcLinear", style = "loop" })
