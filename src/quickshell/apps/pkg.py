#!/usr/bin/env python3
"""Package queries for the Zone-C app store; prints JSON.

  pkg.py status NAME...      installed version of each pacman package / Flatpak id
  pkg.py search QUERY        pacman repos, AUR (yay or paru) and Flathub
  pkg.py info SOURCE NAME    version, size, licence, description, URL
  pkg.py installed           explicitly installed packages and Flatpak apps
  pkg.py updates             pending updates from all three sources
"""
import json
import re
import shutil
import subprocess
import sys

AUR = shutil.which("yay") or shutil.which("paru")
FLATPAK = shutil.which("flatpak")


def run(cmd, timeout=40):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=timeout, env={"LC_ALL": "C", "PATH": "/usr/local/bin:/usr/bin:/bin"}).stdout
    except (OSError, subprocess.TimeoutExpired):
        return ""


def fields(text):
    """pacman -Si / -Qi blocks -> list of dicts."""
    out, cur, key = [], {}, None
    for line in text.splitlines():
        if not line.strip():
            if cur:
                out.append(cur)
            cur, key = {}, None
            continue
        m = re.match(r"^(\S[^:]*?)\s*: (.*)$", line)
        if m:
            key = m.group(1).strip()
            cur[key] = m.group(2).strip()
        elif key:
            cur[key] += " " + line.strip()
    if cur:
        out.append(cur)
    return out


def flatpak_ids():
    if not FLATPAK:
        return {}
    res = {}
    for line in run([FLATPAK, "list", "--app", "--columns=application,version"]).splitlines():
        p = line.split("\t")
        if p and p[0]:
            res[p[0]] = p[1] if len(p) > 1 else ""
    return res


def status(names):
    fl = flatpak_ids()
    out = {}
    pac = [n for n in names if "." not in n or n.count(".") < 2]
    for line in run(["pacman", "-Q"] + pac).splitlines():
        p = line.split()
        if len(p) == 2:
            out[p[0]] = p[1]
    for n in names:
        if n in fl:
            out[n] = fl[n] or "flatpak"
    return out


def search(q):
    res = []
    installed = set(run(["pacman", "-Qq"]).split())
    text = run(["pacman", "-Ss", q])
    lines = text.splitlines()
    for i in range(0, len(lines) - 1, 2):
        m = re.match(r"^(\S+)/(\S+) (\S+)", lines[i])
        if m:
            res.append(dict(src="pacman", name=m.group(2), id=m.group(2), version=m.group(3), desc=lines[i + 1].strip(), installed=m.group(2) in installed))
    if AUR:
        text = run([AUR, "-Ssa", q], timeout=25)
        lines = text.splitlines()
        i = 0
        while i < len(lines) - 1:
            m = re.match(r"^aur/(\S+) (\S+)(?: \(\+(\d+)[^)]*\))?", lines[i])
            if m:
                res.append(dict(src="AUR", name=m.group(1), id=m.group(1), version=m.group(2), votes=int(m.group(3) or 0), desc=lines[i + 1].strip(), installed=m.group(1) in installed))
                i += 2
            else:
                i += 1
    if FLATPAK:
        have = flatpak_ids()
        for line in run([FLATPAK, "search", "--columns=name,description,application,version", q], timeout=25).splitlines():
            p = line.split("\t")
            if len(p) >= 3 and "." in p[2]:
                res.append(dict(src="Flatpak", name=p[0], id=p[2], version=p[3] if len(p) > 3 else "", desc=p[1], installed=p[2] in have))
    ql = q.lower()
    res.sort(key=lambda r: (r["name"].lower() != ql, not r["name"].lower().startswith(ql), -r.get("votes", 0) // 50, r["name"].lower()))
    return res[:150]


def size_mb(s):
    m = re.match(r"([\d.]+)\s*(\w+)", s or "")
    if not m:
        return s or ""
    v, u = float(m.group(1)), m.group(2)
    mb = v * {"B": 1 / 1048576, "KiB": 1 / 1024, "MiB": 1, "GiB": 1024}.get(u, 1)
    return f"{mb / 1024:.1f} GB" if mb >= 1024 else f"{round(mb)} MB" if mb >= 1 else f"{round(mb * 1024)} KB"


def info(src, name):
    if src == "Flatpak":
        if not FLATPAK:
            return {}
        t = run([FLATPAK, "remote-info", "flathub", name], timeout=25)
        f = {}
        for line in t.splitlines():
            m = re.match(r"^\s*(\S[^:]*?):\s*(.*)$", line)
            if m:
                f[m.group(1)] = m.group(2)
        return dict(version=f.get("Version", ""), size=f.get("Installed", f.get("Download", "")), license=f.get("License", ""), desc=(t.splitlines() or [""])[0].split(" - ", 1)[-1].strip(), url="")
    if src == "AUR" and AUR:
        f = (fields(run([AUR, "-Sia", name], timeout=25)) or [{}])[0]
        return dict(version=f.get("Version", ""), size="", license=f.get("Licenses", ""), desc=f.get("Description", ""), url=f.get("URL", ""), votes=f.get("Votes", ""), maintainer=f.get("Maintainer", ""))
    f = (fields(run(["pacman", "-Si", name])) or fields(run(["pacman", "-Qi", name])) or [{}])[0]
    return dict(version=f.get("Version", ""), size=size_mb(f.get("Installed Size", "")), license=f.get("Licenses", ""), desc=f.get("Description", ""), url=f.get("URL", ""), repo=f.get("Repository", ""))


def installed():
    res = []
    foreign = set(run(["pacman", "-Qmq"]).split())
    for f in fields(run(["pacman", "-Qei"])):
        n = f.get("Name", "")
        if not n:
            continue
        res.append(dict(src="AUR" if n in foreign else "pacman", name=n, id=n, version=f.get("Version", ""), desc=f.get("Description", ""), installed=True, size=size_mb(f.get("Installed Size", ""))))
    if FLATPAK:
        for line in run([FLATPAK, "list", "--app", "--columns=name,description,application,version"]).splitlines():
            p = line.split("\t")
            if len(p) >= 3:
                res.append(dict(src="Flatpak", name=p[0], id=p[2], version=p[3] if len(p) > 3 else "", desc=p[1], installed=True))
    return res


def updates():
    res = []
    text = run(["checkupdates"], timeout=60) if shutil.which("checkupdates") else run(["pacman", "-Qu"])
    for line in text.splitlines():
        p = line.split()
        if len(p) >= 4:
            res.append(dict(src="pacman", name=p[0], id=p[0], version=p[3], old=p[1], desc="", installed=True))
    if AUR:
        for line in run([AUR, "-Qua"], timeout=40).splitlines():
            p = line.split()
            if len(p) >= 4:
                res.append(dict(src="AUR", name=p[0], id=p[0], version=p[3], old=p[1], desc="", installed=True))
    if FLATPAK:
        for line in run([FLATPAK, "remote-ls", "--updates", "--app", "--columns=name,application,version"], timeout=40).splitlines():
            p = line.split("\t")
            if len(p) >= 2:
                res.append(dict(src="Flatpak", name=p[0], id=p[1], version=p[2] if len(p) > 2 else "", desc="", installed=True))
    return res


def ratings():
    """Star ratings from ODRS (the open ratings service GNOME Software uses), cached for a day.
    Returns {key: [average, count]} keyed by the AppStream id and by its last segment, lowercased
    ("org.gimp.GIMP" and "gimp"), so pacman package names find their app too."""
    import os, time, urllib.request
    cache = os.path.expanduser("~/.cache/zone-c/appstore/ratings.json")
    raw = None
    try:
        if time.time() - os.path.getmtime(cache) < 86400:
            raw = json.load(open(cache))
    except (OSError, ValueError):
        pass
    if raw is None:
        try:
            with urllib.request.urlopen("https://odrs.gnome.org/1.0/reviews/api/ratings", timeout=20) as r:
                raw = json.load(r)
            os.makedirs(os.path.dirname(cache), exist_ok=True)
            json.dump(raw, open(cache, "w"))
        except Exception:
            try:
                raw = json.load(open(cache))
            except Exception:
                return {}
    out = {}
    for aid, r in raw.items():
        n = sum(r.get("star%d" % i, 0) for i in range(1, 6))
        if n < 3:
            continue
        avg = round(sum(i * r.get("star%d" % i, 0) for i in range(1, 6)) / n, 1)
        key = aid[:-8] if aid.endswith(".desktop") else aid
        for k in (key.lower(), key.split(".")[-1].lower()):
            if k not in out or out[k][1] < n:
                out[k] = [avg, n]
    return out


def main():
    a = sys.argv[1:]
    if not a:
        print(__doc__)
        return
    cmd = a[0]
    out = {"status": lambda: status(a[1:]), "search": lambda: search(" ".join(a[1:])), "info": lambda: info(a[1], a[2]),
           "installed": installed, "updates": updates, "ratings": ratings}.get(cmd, lambda: {})()
    print(json.dumps(dict(cmd=cmd, arg=" ".join(a[1:]), aur=bool(AUR), flatpak=bool(FLATPAK), data=out), ensure_ascii=False))


if __name__ == "__main__":
    main()
