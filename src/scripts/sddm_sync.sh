#!/usr/bin/env bash
# Zone-C: dong bo man dang nhap SDDM (theme zone-thunder) voi theme dang dung cua shell.
# Ghi bang mau + hinh nen hien tai vao <theme>/current/ (thu muc nay thuoc user, tao luc cai dat).
# Dung: sddm_sync.sh [duong-dan-hinh-nen]
#   Khong co tham so -> giu hinh nen da dong bo truoc do, chi cap nhat mau.

THEME_DIR="${ZONE_C_SDDM_THEME:-/usr/share/sddm/themes/zone-thunder}"
CUR="$THEME_DIR/current"
SETTINGS="${XDG_CONFIG_HOME:-$HOME/.config}/zone-c/settings.json"

# Chua cai dat thu muc current/ (can sudo mot lan) -> bo qua, khong bao loi
[ -d "$CUR" ] && [ -w "$CUR" ] || exit 0
[ -f "$SETTINGS" ] || exit 0

exec python3 - "$CUR" "$SETTINGS" "${1:-}" <<'PY'
import json, os, shutil, subprocess, sys

cur, settings_path, wall = sys.argv[1], sys.argv[2], sys.argv[3]
if wall.startswith("file://"):
    wall = wall[7:]

try:
    colors = json.load(open(settings_path)).get("theme", {}).get("colors", {}) or {}
except Exception:
    colors = {}

conf_path = os.path.join(cur, "theme.conf")
old = {}
if os.path.exists(conf_path):
    for line in open(conf_path):
        if "=" in line and not line.lstrip().startswith(("[", "#", ";")):
            k, v = line.split("=", 1)
            old[k.strip()] = v.strip()

conf = {}
for k in ["crust", "mantle", "base", "surface0", "surface1", "surface2", "subtext0", "subtext1",
          "text", "blue", "sapphire", "teal", "mauve", "red"]:
    v = colors.get(k)
    if isinstance(v, str) and v.startswith("#"):
        conf[k] = v
if "surface2" in conf:
    conf["edge"] = conf["surface2"]

def publish(src, name):
    """Chep src thanh current/<name> neu khac; tra ve ten file."""
    dst = os.path.join(cur, name)
    if not (os.path.exists(dst) and os.path.getsize(dst) == os.path.getsize(src)
            and int(os.path.getmtime(dst)) == int(os.path.getmtime(src))):
        tmp = dst + ".tmp"
        shutil.copy2(src, tmp)
        os.chmod(tmp, 0o644)
        os.replace(tmp, dst)
    return name

VIDEO = (".mp4", ".mkv", ".webm", ".mov")
if wall and os.path.isfile(wall):
    ext = os.path.splitext(wall)[1].lower()
    for f in os.listdir(cur):  # don file cu khac duoi
        if f.startswith(("background.", "video.")) and not f.endswith(".tmp"):
            keep = (f == "background" + ext) or (f == "video" + ext) or (ext in VIDEO and f == "background.jpg")
            if not keep:
                os.remove(os.path.join(cur, f))
    if ext in VIDEO:
        conf["video"] = publish(wall, "video" + ext)
        frame = os.path.join(cur, "background.jpg")
        if not os.path.exists(frame) or os.path.getmtime(frame) < os.path.getmtime(wall):
            subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-ss", "1", "-i", wall,
                            "-frames:v", "1", "-q:v", "3", frame], check=False)
            if os.path.exists(frame):
                os.chmod(frame, 0o644)
        conf["background"] = "background.jpg"
    else:
        conf["background"] = publish(wall, "background" + ext)
        conf["video"] = ""
else:
    for k in ("background", "video"):
        if k in old:
            conf[k] = old[k]

if conf == old:
    sys.exit(0)

tmp = conf_path + ".tmp"
with open(tmp, "w") as f:
    f.write("# Ghi tu dong boi Zone-C (scripts/sddm_sync.sh) - dung sua tay\n[General]\n")
    for k, v in conf.items():
        f.write(f"{k}={v}\n")
os.chmod(tmp, 0o644)
os.replace(tmp, conf_path)
PY
