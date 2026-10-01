#!/usr/bin/env bash
# Zone-C: mau terminal theo theme dang dung.
# Ghi ~/.local/state/zone-c/term_theme.sh, duoc doc boi:
#   - ~/.blerc       : mau to cu phap dong lenh (ble.sh)
#   - zonec-banner   : dai mau logo ZONE-C
# Terminal mo sau khi doi theme se nhan mau moi.

SETTINGS="${XDG_CONFIG_HOME:-$HOME/.config}/zone-c/settings.json"
OUT="${XDG_STATE_HOME:-$HOME/.local/state}/zone-c/term_theme.sh"
[ -f "$SETTINGS" ] || exit 0
mkdir -p "$(dirname "$OUT")"

exec python3 - "$SETTINGS" "$OUT" <<'PY'
import json, os, sys

settings_path, out = sys.argv[1], sys.argv[2]
try:
    theme = json.load(open(settings_path)).get("theme", {}) or {}
except Exception:
    sys.exit(0)
c = theme.get("colors", {}) or {}
preset = theme.get("activePreset", "")
mode = theme.get("mode", "dark")

def hx(k, d):
    v = c.get(k)
    return v if isinstance(v, str) and v.startswith("#") and len(v) == 7 else d

def rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))

def mix(a, b, t):
    a, b = rgb(a), rgb(b)
    return "#%02x%02x%02x" % tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))

# Dai mau banner (tren -> duoi). Thunder/Crystal giu dung dai xanh dien goc.
ELECTRIC = ["#cdf5ff", "#8ce1ff", "#50c3ff", "#1ea0ff", "#0f73ff", "#0a4bd7"]
if preset in ("Zone Thunder", "Zone Crystal"):
    banner = ELECTRIC
elif preset == "Zone Frost":
    banner = (["#5d8597", "#4f788b", "#42697c", "#365c6f", "#2c4f61", "#223f4e"] if mode == "light"
              else ["#f4fbfe", "#d6e6ec", "#b3d1dd", "#8fb6c6", "#6f97a8", "#557a8b"])
else:
    top, acc = hx("text", "#e6efff"), hx("blue", "#3d9bff")
    deep = mix(acc, hx("crust", "#030817"), 0.45)
    banner = [mix(top, acc, t / 3) for t in range(3)] + [mix(acc, deep, t / 2) for t in range(3)]

blue, sapphire, teal, mauve = hx("blue", "#3d9bff"), hx("sapphire", "#5cc0ff"), hx("teal", "#62e3ff"), hx("mauve", "#86b4ff")
green, peach, yellow, red = hx("green", "#a6e3a1"), hx("peach", "#fab387"), hx("yellow", "#f9e2af"), hx("red", "#ff5a74")
text, sub1, ov0, ov1 = hx("text", "#e6efff"), hx("subtext1", "#b7c9ee"), hx("overlay0", "#6c7086"), hx("overlay1", "#7f849c")

# Mau to cu phap: lenh = accent, tham so = chu phu, duong dan = accent phu (khong gach chan)
faces = {
    "command_builtin": f"fg={blue},bold", "command_builtin_dot": f"fg={blue},bold",
    "command_file": f"fg={blue}", "command_alias": f"fg={sapphire}", "command_function": f"fg={teal}",
    "command_keyword": f"fg={mauve},bold", "command_jobs": f"fg={blue},bold",
    "command_directory": f"fg={sapphire}", "command_suffix": f"fg={green},bold", "command_suffix_new": f"fg={peach},bold",
    "argument_option": f"fg={sub1}", "argument_error": f"fg={red},underline",
    "filename_directory": f"fg={sapphire}", "filename_executable": f"fg={green}",
    "filename_link": f"fg={teal}", "filename_other": "none", "filename_ls_colors": "none",
    "filename_url": f"fg={sapphire},underline", "filename_warning": f"fg={red}",
    # File dac biet (mac dinh ble.sh co nen mau + gach chan, vd /tmp la sticky dir)
    "filename_directory_sticky": f"fg={sapphire}", "filename_setuid": f"fg={red},bold",
    "filename_setgid": f"fg={yellow},bold", "filename_socket": f"fg={mauve}",
    "filename_pipe": f"fg={yellow}", "filename_block": f"fg={yellow},bold",
    "filename_character": f"fg={yellow}", "filename_orphan": f"fg={red}",
    "syntax_default": "none", "syntax_command": f"fg={blue}",
    "syntax_quoted": f"fg={green}", "syntax_quotation": f"fg={green},bold",
    "syntax_escape": f"fg={mauve}", "syntax_expr": f"fg={sapphire}",
    "syntax_varname": f"fg={peach}", "syntax_param_expansion": f"fg={peach}",
    "syntax_tilde": f"fg={sapphire},bold", "syntax_glob": f"fg={mauve},bold",
    "syntax_brace": f"fg={teal},bold", "syntax_delimiter": "bold",
    "syntax_comment": f"fg={ov0}", "syntax_function_name": f"fg={teal},bold",
    "syntax_document": f"fg={yellow}", "syntax_document_begin": f"fg={yellow},bold",
    "syntax_error": f"fg={red},underline", "syntax_history_expansion": f"fg={mauve},bold",
    "varname_new": f"fg={peach}", "varname_unset": f"fg={ov1}", "varname_empty": f"fg={ov1}",
    "varname_number": f"fg={peach}", "varname_export": f"fg={peach},bold",
    "varname_readonly": f"fg={peach}", "varname_array": f"fg={peach},bold",
    "varname_hash": f"fg={peach},bold", "varname_expr": f"fg={teal},bold",
    "varname_transform": f"fg={teal},bold",
    "auto_complete": f"fg={ov0}",
}

lines = ["# Ghi tu dong boi Zone-C (scripts/term_sync.sh) theo theme: %s (%s) - dung sua tay" % (preset or "?", mode)]
lines.append("ZONEC_BANNER_COLORS=(" + " ".join('"%d;%d;%d"' % rgb(h) for h in banner) + ")")
lines.append("if [[ ${BLE_VERSION-} ]]; then")
lines.append("    bleopt term_true_colors=semicolon")
for k, v in faces.items():
    lines.append(f"    ble-face -s {k} {v}")
lines.append("fi")
content = "\n".join(lines) + "\n"

if os.path.exists(out) and open(out).read() == content:
    sys.exit(0)
tmp = out + ".tmp"
open(tmp, "w").write(content)
os.replace(tmp, out)
PY
