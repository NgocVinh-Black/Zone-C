#!/usr/bin/env python3
# Tao bo con tro ZoneC-Arch: con tro mui ten mac dinh la logo Arch,
# cac con tro khac ke thua Adwaita. Can ImageMagick (magick).
import os
import struct
import subprocess
import sys

HERE = os.path.dirname(os.path.realpath(__file__))
SVG = os.path.join(HERE, "arch-pointer.svg")
THEME = "ZoneC-Arch"
DEST = os.path.expanduser(sys.argv[1] if len(sys.argv) > 1 else f"~/.local/share/icons/{THEME}")
SIZES = [24, 32, 48, 64, 96]
HOT_X, HOT_Y = 0.477, 0.06  # dinh tam giac cua logo
NAMES = ["left_ptr", "default", "arrow", "top_left_arrow", "left-arrow"]


def render(size):
    raw = subprocess.run(
        ["magick", "-background", "none", "-density", "600", SVG,
         "-resize", f"{size}x{size}", "-gravity", "center", "-extent", f"{size}x{size}",
         "-depth", "8", "rgba:-"],
        check=True, capture_output=True).stdout
    px = bytearray()
    for i in range(0, len(raw), 4):
        r, g, b, a = raw[i:i + 4]
        # XCursor dung ARGB premultiplied, little-endian
        px += struct.pack("<I", (a << 24) | (r * a // 255 << 16) | (g * a // 255 << 8) | (b * a // 255))
    return bytes(px)


def build():
    images = [(s, render(s)) for s in SIZES]
    ntoc = len(images)
    out = bytearray(struct.pack("<4sIII", b"Xcur", 16, 0x10000, ntoc))
    pos = 16 + ntoc * 12
    chunks = bytearray()
    for size, px in images:
        out += struct.pack("<III", 0xFFFD0002, size, pos)
        chunk = struct.pack("<IIIIIIIII", 36, 0xFFFD0002, size, 1, size, size,
                            round(size * HOT_X), round(size * HOT_Y), 0) + px
        chunks += chunk
        pos += len(chunk)
    return bytes(out + chunks)


def main():
    cur_dir = os.path.join(DEST, "cursors")
    os.makedirs(cur_dir, exist_ok=True)
    with open(os.path.join(DEST, "index.theme"), "w") as f:
        f.write(f"[Icon Theme]\nName={THEME}\nComment=Zone-C: Arch logo pointer\nInherits=Adwaita\n")
    with open(os.path.join(cur_dir, NAMES[0]), "wb") as f:
        f.write(build())
    for name in NAMES[1:]:
        link = os.path.join(cur_dir, name)
        if os.path.lexists(link):
            os.remove(link)
        os.symlink(NAMES[0], link)
    print(f"Installed cursor theme {THEME} -> {DEST}")


if __name__ == "__main__":
    main()
