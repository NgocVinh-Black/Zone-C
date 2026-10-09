hl.monitor({
  output = "",
  mode = "preferred",
  position = "auto",
  scale = 1.0,
})

-- Man hinh laptop 2880x1800: scale 2 (giu nguyen khi hyprctl reload)
hl.monitor({
  output = "eDP-1",
  mode = "preferred",
  position = "auto",
  scale = 2,
})
