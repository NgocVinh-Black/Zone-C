#!/usr/bin/env python3
"""Colours the grayscale layers (../gray) with the current zone-c theme.

Reads ~/.local/state/zone-c/qs_colors.json, maps gray -> a five-stop ramp built from the
theme (dark outline .. cloud highlight, in the theme's hue), writes ../themed/<hash>/l-*.png once per palette,
and prints one JSON line: the folder and the colours the overlay's bubbles use.
"""
import colorsys
import glob
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
GRAY = os.path.join(ROOT, "gray")
THEMED = os.path.join(ROOT, "themed")
COLORS = os.path.expanduser(os.environ.get("QS_COLORS_JSON", "~/.local/state/zone-c/qs_colors.json"))

# The look the cat was drawn with, used when no theme file can be read.
FALLBACK = {"crust": "#252f34", "blue": "#d6e6ec"}
# (lightness, saturation) of the original five tones: outline .. cloud highlight
RAMP = [(0.325, 0.24), (0.433, 0.21), (0.657, 0.29), (0.804, 0.46), (0.929, 0.56)]


def rgb(h):
    h = h.lstrip("#")[-6:]
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def hexc(c):
    return "#%02x%02x%02x" % tuple(max(0, min(255, round(v))) for v in c)


def load_theme():
    try:
        with open(COLORS) as f:
            c = json.load(f)
        c = c.get("colors", c)
        return {k: c.get(k, FALLBACK[k]) for k in FALLBACK}
    except (OSError, ValueError, AttributeError):
        return dict(FALLBACK)


def main():
    theme = load_theme()
    crust, accent = rgb(theme["crust"]), rgb(theme["blue"])
    # Only the theme's hue (and how vivid it is) is taken; lightness per stop is fixed to the
    # cat's original drawing so the outline, face and cloud keep their contrast in any theme.
    hue, _, sat = colorsys.rgb_to_hls(*(v / 255 for v in accent))
    vivid = max(0.5, min(1.6, sat / 0.37))
    ramp = [colorsys.hls_to_rgb(hue, l, min(1.0, s * vivid)) for l, s in RAMP]
    stops = [hexc(tuple(v * 255 for v in c)) for c in ramp]

    # rebuilt when the palette or any gray layer changes
    layers = sorted(glob.glob(os.path.join(GRAY, "l-*.png")))
    stamp = ",".join("%s:%d" % (os.path.basename(f), os.stat(f).st_mtime_ns) for f in layers)
    key = hashlib.sha1((",".join(stops) + stamp).encode()).hexdigest()[:10]
    out = os.path.join(THEMED, key)
    if not os.path.isdir(out):
        os.makedirs(THEMED, exist_ok=True)
        tmp = tempfile.mkdtemp(dir=THEMED, prefix=".tmp-")
        clut = os.path.join(tmp, "clut.png")
        subprocess.run(["magick", "-size", "1x1"] + ["xc:" + s for s in stops]
                       + ["+append", "-filter", "triangle", "-resize", "256x1!", clut], check=True)
        for src in layers:
            subprocess.run(["magick", src, "-channel", "RGB", clut, "-clut", "+channel",
                            os.path.join(tmp, os.path.basename(src))], check=True)
        os.remove(clut)
        os.rename(tmp, out)
    # keep only the current palette's folder
    for d in glob.glob(os.path.join(THEMED, "*")) + glob.glob(os.path.join(THEMED, ".tmp-*")):
        if d != out:
            shutil.rmtree(d, ignore_errors=True)

    print(json.dumps({
        "dir": out,
        "outline": stops[0], "mid": stops[2], "accent": stops[3], "light": stops[4],
        "shadow": hexc(crust),
    }))


if __name__ == "__main__":
    sys.exit(main())
