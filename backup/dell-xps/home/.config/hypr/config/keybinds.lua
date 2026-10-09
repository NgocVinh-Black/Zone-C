local mainMod = _G.mainMod or "SUPER"
local terminal = _G.terminal or "kitty"
local browser = "google-chrome-stable"
local editor = "code"
local fileExplorer = "nautilus"
local fn = require("config/functions")

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

------------------------------------------------------------------
-- Phim tat cu (tu repo arch-linux-setup), chuyen sang zone-c
------------------------------------------------------------------

-- Launcher: nhan nha SUPER.
hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd("zone-c msg toggle launcher"), { release = true })
-- Da bo launcher-im-guard: o search tu nhan phim truc tiep (directKeys) nen khong can tat/bat Unikey nua

-- Media
hl.bind("CTRL + SUPER + Space", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("CTRL + SUPER + Equal", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("CTRL + SUPER + Minus", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl stop"), { locked = true })

-- Workspaces
for i = 1, 10 do
  local key = i % 10 -- 10 maps to key 0
  hl.bind(mainMod .. " + " .. key, hl.dsp.exec_cmd("zone-c msg workspace " .. i))
  hl.bind(mainMod .. " + ALT + " .. key, hl.dsp.exec_cmd("zone-c msg workspace " .. i .. " move"))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.exec_cmd("zone-c msg workspace " .. i .. " move"))
  hl.bind("CTRL + SUPER + " .. key, fn.wsaction("focus", "group", i))
  hl.bind("CTRL + SUPER + ALT + " .. key, fn.wsaction("move", "group", i))
end

-- Go to workspace -1/+1
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "-1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "+1" }))
hl.bind("CTRL + SUPER + Left", hl.dsp.focus({ workspace = "-1" }), { repeating = true })
hl.bind("CTRL + SUPER + Right", hl.dsp.focus({ workspace = "+1" }), { repeating = true })
hl.bind("SUPER + Page_Up", hl.dsp.focus({ workspace = "-1" }), { repeating = true })
hl.bind("SUPER + Page_Down", hl.dsp.focus({ workspace = "+1" }), { repeating = true })
hl.bind("CTRL + SUPER + mouse_down", hl.dsp.focus({ workspace = "-10" }))
hl.bind("CTRL + SUPER + mouse_up", hl.dsp.focus({ workspace = "+10" }))

-- Move window to workspace -1/+1
hl.bind("SUPER + ALT + Page_Up", hl.dsp.window.move({ workspace = "-1" }), { repeating = true })
hl.bind("SUPER + ALT + Page_Down", hl.dsp.window.move({ workspace = "+1" }), { repeating = true })
hl.bind("SUPER + ALT + mouse_down", hl.dsp.window.move({ workspace = "-1" }))
hl.bind("SUPER + ALT + mouse_up", hl.dsp.window.move({ workspace = "+1" }))
hl.bind("CTRL + SUPER + SHIFT + Right", hl.dsp.window.move({ workspace = "+1" }), { repeating = true })
hl.bind("CTRL + SUPER + SHIFT + Left", hl.dsp.window.move({ workspace = "-1" }), { repeating = true })

-- Move window to/from special workspace
hl.bind("CTRL + SUPER + SHIFT + Up", hl.dsp.window.move({ workspace = "special:special" }))
hl.bind("CTRL + SUPER + SHIFT + Down", hl.dsp.window.move({ workspace = "e+0" }))
hl.bind("SUPER + ALT + S", hl.dsp.window.move({ workspace = "special:special" }))

-- Window groups
hl.bind("ALT + TAB", hl.dsp.window.cycle_next(), { repeating = true })
hl.bind("SHIFT + ALT + TAB", hl.dsp.window.cycle_next({ next = false }), { repeating = true })
hl.bind("CTRL + ALT + Tab", hl.dsp.group.next(), { repeating = true })
hl.bind("CTRL + SHIFT + ALT + Tab", hl.dsp.group.prev(), { repeating = true })
hl.bind("SUPER + Comma", hl.dsp.group.toggle())
hl.bind("SUPER + U", hl.dsp.window.move({ out_of_group = true }))
hl.bind("SUPER + SHIFT + Comma", hl.dsp.group.lock_active())

-- Window actions
hl.bind("SUPER + Left", hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + Right", hl.dsp.focus({ direction = "right" }))
hl.bind("SUPER + Up", hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + Down", hl.dsp.focus({ direction = "down" }))
hl.bind("SUPER + SHIFT + Left", hl.dsp.window.move({ direction = "left" }))
hl.bind("SUPER + SHIFT + Right", hl.dsp.window.move({ direction = "right" }))
hl.bind("SUPER + SHIFT + Up", hl.dsp.window.move({ direction = "up" }))
hl.bind("SUPER + SHIFT + Down", hl.dsp.window.move({ direction = "down" }))

-- Resize phai boc trong function de do kich thuoc cua so dang focus moi lan bam
-- (goi fn.resize_active_window luc nap config se tra ve nil).
local function bind_resize(key, x, y)
  hl.bind(key, function()
    local delta = fn.resize_active_window(x, y)
    if delta then
      hl.dispatch(hl.dsp.window.resize(delta))
    end
  end, { repeating = true })
end

bind_resize("SUPER + SHIFT + Minus", 0, -10)
bind_resize("SUPER + SHIFT + Equal", 0, 10)
bind_resize("SUPER + ALT + Left", -10, 0)
bind_resize("SUPER + ALT + Right", 10, 0)
bind_resize("SUPER + ALT + Up", 0, -10)
bind_resize("SUPER + ALT + Down", 0, 10)
bind_resize("SUPER + Equal", 10, 0)
bind_resize("SUPER + Minus", -10, 0)

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + Z", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind("SUPER + X", hl.dsp.window.resize(), { mouse = true })
hl.bind("CTRL + SUPER + Backslash", hl.dsp.window.center())
hl.bind("CTRL + SUPER + ALT + Backslash", function()
  local size = fn.resize_by_screen(55, 70)
  if size then hl.dispatch(hl.dsp.window.resize(size)) end
  hl.dispatch(hl.dsp.window.center())
end)
hl.bind("SUPER + ALT + Backslash", function()
  local a = hl.get_active_window()
  if a then
    local pip = fn.move_actions(a) or {}
    if not a.floating then table.insert(pip, 1, hl.dsp.window.float()) end
    table.insert(pip, hl.dsp.window.pin({ action = "on", window = "address:" .. a.address }))
    for _, x in ipairs(pip) do
      hl.dispatch(x)
    end
  end
end)
hl.bind("SUPER + P", hl.dsp.window.pin())
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind("SUPER + ALT + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind("SUPER + ALT + Space", hl.dsp.window.float())
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/smart-close"))
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/smart-close --force"))

-- Apps
hl.bind("SUPER + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind("SUPER + W", hl.dsp.exec_cmd(browser))
hl.bind("SUPER + G", hl.dsp.exec_cmd(browser))
hl.bind("SUPER + C", hl.dsp.exec_cmd(editor))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileExplorer))
hl.bind("CTRL + ALT + V", hl.dsp.exec_cmd("pavucontrol"))
hl.bind("CTRL + ALT + B", hl.dsp.exec_cmd("blueman-manager"))

-- Screenshot / record
hl.bind("Print", hl.dsp.exec_cmd("zone-c screenshot"), { locked = true })
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("zone-c screenshot --edit"), { locked = true })
hl.bind("SUPER + Print", hl.dsp.exec_cmd("zone-c screenshot --full"), { locked = true })
hl.bind("SUPER + SHIFT + Print", hl.dsp.exec_cmd("zone-c screenshot --full --edit"), { locked = true })
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/flameshot-gui"))
hl.bind("SUPER + SHIFT + ALT + S", hl.dsp.exec_cmd("zone-c screenshot"))
hl.bind("SUPER + ALT + R", hl.dsp.exec_cmd("zone-c screenshot --record"))

-- Lock / sleep
hl.bind("XF86PowerOff", hl.dsp.exec_cmd("zone-c lock"), { locked = true })
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("zone-c lock"), { locked = true })
hl.bind("SUPER + SHIFT + L", hl.dsp.exec_cmd("systemctl suspend-then-hibernate"), { locked = true })

------------------------------------------------------------------
-- Zone-C: do sang, am luong, media, panel
------------------------------------------------------------------

hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("zone-c brightness lower"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("zone-c brightness raise"), { locked = true })

hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("zone-c volume mic-toggle"), { locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("zone-c volume mute-toggle"), { locked = true })
hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd("zone-c volume mute-toggle"), { locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("zone-c volume lower"), { repeating = true, locked = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("zone-c volume raise"), { repeating = true, locked = true })

hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("zone-c reload"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("zone-c msg toggle clipboard"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("zone-c msg toggle launcher"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("zone-c msg toggle music"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("zone-c msg toggle system"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("zone-c msg toggle wallpaper"))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("zone-c msg toggle calendar"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("zone-c msg toggle network"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("zone-c msg toggle volume"))
hl.bind(mainMod .. " + H", hl.dsp.exec_cmd("zone-c msg toggle guide"))
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/keybinds-help"))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("zone-c msg toggle autohide"))

------------------------------------------------------------------
-- float-cat: nhan SUPER + K roi keo con meo bang chuot trai (khong giu SUPER,
-- vi SUPER + chuot trai la keo cua so); tha chuot la dat xuong
------------------------------------------------------------------
hl.bind("SUPER + K", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/float-cat grab toggle"))
-- float-cat: bat / tat con meo
hl.bind("SUPER + SHIFT + K", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/float-cat toggle"))
-- float-cat: phim Copilot (gui SUPER + SHIFT + F23) cung bat / tat con meo
hl.bind("SUPER + SHIFT + F23", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/float-cat toggle"))
