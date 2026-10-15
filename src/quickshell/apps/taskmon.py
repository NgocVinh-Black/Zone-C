#!/usr/bin/env python3
"""Sampler for the Zone-C task manager: one JSON line per second on stdout.

Processes are grouped by executable (Chrome's helpers count as Chrome) with CPU % since the last sample,
resident memory and disk I/O rate. System totals cover CPU (and per core), memory, the busiest disk,
the default network interface and the GPU when the kernel exposes it.
"""
import json
import os
import pwd
import socket
import sys
import time

HZ = os.sysconf("SC_CLK_TCK")
PAGE = os.sysconf("SC_PAGE_SIZE")
NCPU = os.cpu_count() or 1
# processes run by an interpreter are named after their script (comm), not the interpreter binary
INTERP = ("python", "bash", "sh", "dash", "zsh", "fish", "node", "perl", "ruby", "java", "lua", "qemu")


def read(path, default=""):
    try:
        with open(path) as f:
            return f.read()
    except OSError:
        return default


def cpu_times():
    out = []
    for line in read("/proc/stat").splitlines():
        if not line.startswith("cpu"):
            break
        v = [int(x) for x in line.split()[1:]]
        idle = v[3] + (v[4] if len(v) > 4 else 0)
        out.append((sum(v), idle))
    return out


def users():
    cache = {}

    def name(uid):
        if uid not in cache:
            try:
                cache[uid] = pwd.getpwuid(uid).pw_name
            except KeyError:
                cache[uid] = str(uid)
        return cache[uid]
    return name


uname = users()


def procs():
    out = {}
    for pid in os.listdir("/proc"):
        if not pid.isdigit():
            continue
        stat = read(f"/proc/{pid}/stat")
        if not stat:
            continue
        r = stat.rfind(")")
        comm = stat[stat.find("(") + 1:r]
        f = stat[r + 2:].split()
        ppid = int(f[1])
        ticks = int(f[11]) + int(f[12])
        threads = int(f[17])
        start = int(f[19])
        rss = int(f[21]) * PAGE
        io = 0
        for line in read(f"/proc/{pid}/io").splitlines():
            if line.startswith(("read_bytes", "write_bytes")):
                io += int(line.split()[1])
        try:
            uid = os.stat(f"/proc/{pid}").st_uid
        except OSError:
            continue
        exe = ""
        try:
            exe = os.path.basename(os.readlink(f"/proc/{pid}/exe"))
        except OSError:
            pass
        out[int(pid)] = dict(comm=comm, exe=exe or comm, ppid=ppid, ticks=ticks, threads=threads, start=start, rss=rss, io=io, uid=uid)
    return out


def meminfo():
    m = {}
    for line in read("/proc/meminfo").splitlines():
        k, v = line.split(":", 1)
        m[k] = int(v.split()[0]) * 1024
    return m


def disks():
    whole = {d for d in os.listdir("/sys/block") if not d.startswith(("loop", "ram", "zram", "dm-", "sr"))}
    out = {}
    for line in read("/proc/diskstats").splitlines():
        f = line.split()
        if f[2] in whole:
            out[f[2]] = (int(f[5]) * 512, int(f[9]) * 512, int(f[12]))   # read bytes, written bytes, ms busy
    return out


def default_iface():
    for line in read("/proc/net/route").splitlines()[1:]:
        f = line.split()
        if f[1] == "00000000":
            return f[0]
    return ""


def net(iface):
    for line in read("/proc/net/dev").splitlines()[2:]:
        name, rest = line.split(":", 1)
        if name.strip() == iface:
            f = rest.split()
            return int(f[0]), int(f[8])
    return 0, 0


def ipv4(iface):
    try:
        import fcntl
        import struct
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        return socket.inet_ntoa(fcntl.ioctl(s.fileno(), 0x8915, struct.pack("256s", iface[:15].encode()))[20:24])
    except Exception:
        return ""


def gpu():
    base = "/sys/class/drm"
    for card in sorted(os.listdir(base)) if os.path.isdir(base) else []:
        dev = f"{base}/{card}/device"
        busy = read(f"{dev}/gpu_busy_percent").strip()
        if busy:
            temp = ""
            hw = f"{dev}/hwmon"
            if os.path.isdir(hw):
                for h in os.listdir(hw):
                    t = read(f"{hw}/{h}/temp1_input").strip()
                    if t:
                        temp = int(t) // 1000
                        break
            vram = read(f"{dev}/mem_info_vram_used").strip()
            return dict(busy=int(busy), temp=temp, vram=int(vram) if vram else 0)
    return None


def cpu_temp():
    for z in sorted(os.listdir("/sys/class/thermal")) if os.path.isdir("/sys/class/thermal") else []:
        t = read(f"/sys/class/thermal/{z}/type").strip()
        if t in ("x86_pkg_temp", "k10temp", "cpu-thermal", "acpitz"):
            v = read(f"/sys/class/thermal/{z}/temp").strip()
            if v:
                return int(v) // 1000
    for h in sorted(os.listdir("/sys/class/hwmon")) if os.path.isdir("/sys/class/hwmon") else []:
        if read(f"/sys/class/hwmon/{h}/name").strip() in ("coretemp", "k10temp", "zenpower"):
            v = read(f"/sys/class/hwmon/{h}/temp1_input").strip()
            if v:
                return int(v) // 1000
    return None


def static_info():
    model = ""
    for line in read("/proc/cpuinfo").splitlines():
        if line.startswith("model name"):
            model = line.split(":", 1)[1].strip()
            break
    return dict(cpuModel=model, threads=NCPU, host=socket.gethostname())


def main():
    me = os.getuid()
    print(json.dumps(dict(kind="static", **static_info())), flush=True)
    prev_cpu, prev_p, prev_d, t0 = cpu_times(), procs(), disks(), time.time()
    iface = default_iface()
    prev_n = net(iface)
    time.sleep(1)
    while True:
        now = time.time()
        dt = max(0.2, now - t0)
        cur_cpu, cur_p, cur_d = cpu_times(), procs(), disks()
        cpus = []
        for (a, ai), (b, bi) in zip(prev_cpu, cur_cpu):
            tot = b - a
            cpus.append(round(100 * (1 - (bi - ai) / tot), 1) if tot > 0 else 0)

        groups = {}
        for pid, p in cur_p.items():
            q = prev_p.get(pid)
            cpu = (p["ticks"] - q["ticks"]) / HZ / dt * 100 / NCPU if q and q["start"] == p["start"] else 0
            io = (p["io"] - q["io"]) / dt if q and q["start"] == p["start"] else 0
            if pid == 2 or p["ppid"] == 2:
                continue    # kernel threads
            name = p["exe"]
            if name.startswith(INTERP):
                args = read(f"/proc/{pid}/cmdline").split("\0")[1:]
                script = "" if "-c" in args[:2] else next((a for a in args if a and not a.startswith("-")), "")
                name = os.path.basename(script) if script else p["comm"]
            key = (name, p["uid"])
            g = groups.get(key)
            if not g:
                g = groups[key] = dict(name=name, comm=p["comm"], user=uname(p["uid"]), mine=p["uid"] == me, pid=pid, pids=[], cpu=0.0, rss=0, io=0.0, threads=0)
            g["pids"].append(pid)
            g["pid"] = min(g["pid"], pid)
            g["cpu"] += cpu
            g["rss"] += p["rss"]
            g["io"] += max(0, io)
            g["threads"] += p["threads"]
        plist = sorted(groups.values(), key=lambda g: (-g["cpu"], -g["rss"]))[:120]
        for g in plist:
            g["cpu"] = round(g["cpu"], 1)
            g["io"] = round(g["io"])
            g["n"] = len(g["pids"])
            g["pids"] = g["pids"][:64]

        m = meminfo()
        total, avail = m.get("MemTotal", 0), m.get("MemAvailable", 0)
        cache = m.get("Cached", 0) + m.get("Buffers", 0)
        swap_t, swap_f = m.get("SwapTotal", 0), m.get("SwapFree", 0)

        disk = None
        for name, (r, w, busy) in cur_d.items():
            q = prev_d.get(name)
            if not q:
                continue
            d = dict(name=name, read=round((r - q[0]) / dt), write=round((w - q[1]) / dt), busy=min(100, round((busy - q[2]) / (dt * 10))),
                     size=int(read(f"/sys/block/{name}/size", "0").strip() or 0) * 512, model=read(f"/sys/block/{name}/device/model").strip())
            if disk is None or d["busy"] > disk["busy"] or (d["busy"] == disk["busy"] and d["size"] > disk["size"]):
                disk = d

        iface = default_iface() or iface
        rx, tx = net(iface)
        n = dict(iface=iface, rx=max(0, round((rx - prev_n[0]) / dt)), tx=max(0, round((tx - prev_n[1]) / dt)), ip=ipv4(iface) if iface else "", wifi=iface.startswith("wl"))
        prev_n = (rx, tx)

        threads = sum(p["threads"] for p in cur_p.values())
        up = float(read("/proc/uptime", "0").split()[0])
        print(json.dumps(dict(kind="sample", cpu=cpus[0] if cpus else 0, cores=cpus[1:], temp=cpu_temp(), procs=len(cur_p), threads=threads, uptime=round(up),
                              mem=dict(total=total, used=total - avail, cache=cache, avail=avail, swapTotal=swap_t, swapUsed=swap_t - swap_f),
                              disk=disk, net=n, gpu=gpu(), list=plist)), flush=True)
        prev_cpu, prev_p, prev_d, t0 = cur_cpu, cur_p, cur_d, now
        time.sleep(1)


if __name__ == "__main__":
    try:
        main()
    except (BrokenPipeError, KeyboardInterrupt):
        sys.exit(0)
