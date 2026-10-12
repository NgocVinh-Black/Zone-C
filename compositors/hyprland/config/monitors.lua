hl.monitor({
  output = "",
  mode = "preferred",
  position = "auto",
  scale = 1.0,
})

-- Doc scale tu ~/.config/zone-c/settings.json (display.monitors.<ten>.scale)
-- de scale chon trong cai dat zone-c duoc giu lai sau khi khoi dong lai
local function zonec_scales()
  local scales = {}
  local f = io.open(os.getenv("HOME") .. "/.config/zone-c/settings.json", "r")
  if not f then return scales end
  local text = f:read("*a")
  f:close()
  local monitors = text:match('"monitors"%s*:%s*(%b{})')
  if not monitors then return scales end
  for name, body in monitors:gmatch('"([^"]+)"%s*:%s*(%b{})') do
    local s = tonumber(body:match('"scale"%s*:%s*([%d%.]+)'))
    if s and s > 0 then scales[name] = s end
  end
  return scales
end

local scales = zonec_scales()

-- Man hinh laptop 2880x1800: mac dinh 1.6 neu zone-c chua luu gi
scales["eDP-1"] = scales["eDP-1"] or 1.6

for name, s in pairs(scales) do
  hl.monitor({
    output = name,
    mode = "preferred",
    position = "auto",
    scale = s,
  })
end
