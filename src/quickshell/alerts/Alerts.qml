import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "../"
import "../frost"

// System alerts of the Frost design (Alerts.dc.html, right): low battery, USB drive plugged in,
// restart needed after a kernel update, CPU running hot. Sent as notifications carrying the
// x-zone-c-alert hint so FrostToasts draws them as alert cards; the chosen action comes back here.
Scope {
    id: root

    // notify-send --wait prints the chosen action id
    Component {
        id: sender
        Process {
            id: p
            property var handler: null
            stdout: StdioCollector { onStreamFinished: { let a = this.text.trim(); if (a && p.handler) p.handler(a); p.destroy(); } }
        }
    }
    function alert(kind, title, body, actions, handler, urgency) {
        // cards with a decision stay until answered; the others fade like normal toasts
        let ms = ({ bat: 0, restart: 0, usb: 15000, hot: 8000 })[kind];
        let cmd = ["notify-send", "--wait", "-a", "Zone-C", "-u", urgency || "normal", "-t", String(ms), "--hint=string:x-zone-c-alert:" + kind];
        for (const a of actions) cmd.push("--action=" + a[0] + "=" + a[1]);
        cmd.push(title, body);
        let p = sender.createObject(root, { command: cmd, handler: handler });
        p.running = true;
    }

    // ---------- low battery ----------
    readonly property var bat: UPower.displayDevice
    readonly property bool low: bat.ready && bat.isLaptopBattery && bat.percentage <= 0.10 && bat.state === UPowerDeviceState.Discharging
    property bool lowShown: false
    onLowChanged: {
        if (!low) { if (bat.state !== UPowerDeviceState.Discharging) lowShown = false; return; }
        if (lowShown) return;
        lowShown = true;
        let mins = bat.timeToEmpty > 0 ? Math.round(bat.timeToEmpty / 60) : 0;
        alert("bat", Fz.tr("Pin yếu · ") + Math.round(bat.percentage * 100) + "%", (mins ? Fz.tr("Còn khoảng ") + mins + Fz.tr(" phút. ") : "") + Fz.tr("Hãy cắm sạc sớm."),
              [["saver", Fz.tr("Bật tiết kiệm pin")], ["settings", Fz.tr("Cài đặt nguồn")]],
              a => { if (a === "saver") PowerProfiles.profile = PowerProfile.PowerSaver; else Fz.open("settings", "power"); }, "critical");
    }

    // ---------- USB drives ----------
    property var mounts: null
    Process {
        id: usbProbe
        command: ["bash", "-c", "findmnt -rn -o TARGET,FSTYPE,SOURCE | awk -v u=\"/run/media/$USER/\" 'index($1,u)==1'; true"]
        stdout: StdioCollector {
            onStreamFinished: {
                let now = {};
                this.text.trim().split("\n").filter(l => l).forEach(l => { let c = l.split(" "); now[c[0].replace(/\\x20/g, " ")] = { fs: c[1], dev: c[2] }; });
                if (root.mounts !== null) for (const t in now) if (!(t in root.mounts)) root.usbAdded(t, now[t]);
                root.mounts = now;
            }
        }
    }
    Timer { interval: 3000; repeat: true; running: true; triggeredOnStart: true; onTriggered: usbProbe.running = true }
    Process { id: usbSize; property string target; property var info
        stdout: StdioCollector { onStreamFinished: {
            let sz = this.text.trim(), name = usbSize.target.split("/").pop();
            root.alert("usb", Fz.tr("Đã cắm USB · ") + name + (sz ? " " + sz : ""), usbSize.info.fs + " · " + usbSize.target,
                       [["open", Fz.tr("Mở trong Tệp")], ["eject", Fz.tr("Tháo an toàn")]],
                       a => { if (a === "open") Fz.open("files", usbSize.target); else Quickshell.execDetached(["bash", "-c", "udisksctl unmount -b \"$1\" && udisksctl power-off -b \"$1\"", "_", usbSize.info.dev]); });
        } } }
    function usbAdded(target, info) {
        usbSize.target = target; usbSize.info = info;
        usbSize.command = ["bash", "-c", "lsblk -dno SIZE \"$1\" 2>/dev/null | xargs", "_", info.dev];
        usbSize.running = true;
    }

    // ---------- restart after a kernel update ----------
    property bool restartShown: false
    Process {
        id: kernelProbe
        command: ["bash", "-c", "[ -d /usr/lib/modules/$(uname -r) ] && exit 0; v=$(ls -t /usr/lib/modules | head -1); n=$(tac /var/log/pacman.log 2>/dev/null | awk '/transaction started/{exit} /\\[ALPM\\] (upgraded|installed)/{c++} END{print c+0}'); echo \"$n|$v\""]
        stdout: StdioCollector {
            onStreamFinished: {
                let t = this.text.trim();
                if (!t || root.restartShown) return;
                root.restartShown = true;
                let p = t.split("|");
                root.alert("restart", Fz.tr("Cập nhật xong") + (Number(p[0]) > 0 ? " " + p[0] + Fz.tr(" gói") : ""), Fz.tr("Kernel mới ") + (p[1] || "") + Fz.tr(" cần khởi động lại."),
                           [["reboot", Fz.tr("Khởi động lại")], ["later", Fz.tr("Để sau")]], a => { if (a === "reboot") Fz.open("power", "reboot"); });
            }
        }
    }
    Timer { interval: 600000; repeat: true; running: !root.restartShown; triggeredOnStart: true; onTriggered: kernelProbe.running = true }

    // ---------- CPU temperature ----------
    property int hotFor: 0
    property double lastHot: 0
    Process {
        id: tempProbe
        command: ["bash", "-c", "for h in /sys/class/hwmon/*; do case $(cat $h/name 2>/dev/null) in coretemp|k10temp|zenpower) cat $h/temp1_input; exit;; esac; done; cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                let t = Math.round(Number(this.text.trim()) / 1000);
                root.hotFor = t >= 90 ? root.hotFor + 1 : 0;
                if (root.hotFor < 3 || Date.now() - root.lastHot < 600000) return;
                root.lastHot = Date.now();
                let perf = PowerProfiles.profile === PowerProfile.Performance;
                if (perf) PowerProfiles.profile = PowerProfile.Balanced;
                root.alert("hot", Fz.tr("CPU đang nóng · ") + t + "°C", perf ? Fz.tr("Đã chuyển sang chế độ Cân bằng") : Fz.tr("Hãy để máy nghỉ một chút"), [], null);
            }
        }
    }
    Timer { interval: 5000; repeat: true; running: true; onTriggered: tempProbe.running = true }
}
