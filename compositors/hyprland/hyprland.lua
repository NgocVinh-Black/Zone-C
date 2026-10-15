require("config/variables")
require("config/env")
require("config/autostart")
require("config/monitors")
require("config/settings")
require("config/keybinds")

-- Zone-C Settings keeps your input, cursor and accessibility choices in this file (rewritten from the app)
pcall(dofile, os.getenv("HOME") .. "/.config/zone-c/hyprland-user.lua")
