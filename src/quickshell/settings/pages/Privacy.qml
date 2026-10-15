import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../"
import "../../"
import "../../frost"

// Quyền riêng tư: lock-screen wallpaper and notification privacy, apps using the camera and the
// microphone right now, location, the firewall (ufw), disk encryption, polkit preview and telemetry.
Column {
    id: page
    property var app
    width: parent ? parent.width : 0

    property var d: ({})
    Process {
        id: probe
        running: true
        command: ["bash", "-c", "cams=$(for v in /dev/video*; do fuser \"$v\" 2>/dev/null; done | tr ' ' '\\n' | grep -E '^[0-9]+$' | sort -u | xargs -r -I{} cat /proc/{}/comm | sort -u | tr '\\n' ','); echo \"cams=$cams\";"
            + "echo \"ufw=$(command -v ufw >/dev/null && systemctl is-active ufw)\"; echo \"crypt=$(lsblk -no TYPE,FSTYPE | grep -cE 'crypt|crypto_LUKS')\"; echo \"telemetry=$(awk -F= '/^ENABLE_TELEMETRY=/{gsub(/\\\"/,\"\",$2); print $2}' \"$1\" 2>/dev/null)\"", "_", Caching.stateDir + "/version"]
        stdout: StdioCollector { onStreamFinished: { let o = {}; this.text.split("\n").forEach(l => { let i = l.indexOf("="); if (i > 0) o[l.slice(0, i)] = l.slice(i + 1); }); page.d = o; } }
    }
    Timer { interval: 5000; repeat: true; running: true; onTriggered: probe.running = true }
    Process { id: run; onExited: probe.running = true }
    readonly property var micApps: { let s = {}; for (const n of Audio.apps) if (n.isStream && !n.isSink) s[Audio.getNodeAppName(n)] = true; return Object.keys(s); }
    readonly property var camApps: (d.cams || "").split(",").filter(x => x)

    H3 { first: true; text: Fz.tr("Màn hình khóa") }
    Grp {
        width: parent.width
        SRow { title: Fz.tr("Hình nền khóa"); sub: Fz.tr("Dùng hình nền hiện tại (video dùng khung hình tĩnh)"); FBtn { text: Fz.tr("Đổi hình nền"); onClicked: Fz.open("wallpaper") } }
        SRow { title: Fz.tr("Ẩn nội dung thông báo khi khóa"); CfgToggle { key: "lock.hideNotifications"; def: true } }
    }

    H3 { text: Fz.tr("Quyền ứng dụng") }
    Grp {
        width: parent.width
        SRow { icon: "s-cam"; title: "Camera"; sub: page.camApps.length ? Fz.tr("Đang dùng: ") + page.camApps.join(", ") : Fz.tr("Không có ứng dụng nào đang dùng") }
        SRow { icon: "s-mic"; title: Fz.tr("Micro"); sub: page.micApps.length ? Fz.tr("Đang dùng: ") + page.micApps.join(", ") : Fz.tr("Không có ứng dụng nào đang dùng") }
        SRow {
            icon: "s-pin"; title: Fz.tr("Vị trí"); sub: Fz.tr("Dùng cho thời tiết và đèn ngủ · ") + (Location.city && Location.city !== "Unknown" ? Location.city : Fz.tr("chưa xác định"))
            FBtn { text: Fz.tr("Thiết lập"); onClicked: page.app.page = "general" }
        }
    }

    H3 { text: Fz.tr("Bảo mật") }
    Grp {
        width: parent.width
        SRow {
            title: Fz.tr("Tường lửa"); sub: page.d.ufw === "" ? Fz.tr("Cần gói ufw") : Fz.tr("ufw · chặn kết nối đến")
            FToggle {
                enabled: page.d.ufw !== "" && page.d.ufw !== undefined; opacity: enabled ? 1 : 0.5
                on: page.d.ufw === "active"
                onToggled: (v) => { run.command = ["pkexec", "bash", "-c", v ? "systemctl enable --now ufw && ufw --force enable" : "ufw disable && systemctl disable --now ufw"]; run.running = true; }
            }
        }
        SRow { title: Fz.tr("Mã hóa ổ đĩa"); sub: Number(page.d.crypt) > 0 ? "LUKS" : Fz.tr("Ổ hệ thống không dùng LUKS"); FChip { kind: Number(page.d.crypt) > 0 ? "ok" : ""; text: Number(page.d.crypt) > 0 ? Fz.tr("Đang bật") : Fz.tr("Không mã hóa"); anchors.verticalCenter: parent.verticalCenter } }
        SRow { title: Fz.tr("Tác nhân Polkit"); sub: Fz.tr("Hộp thoại xác thực của Zone-C"); FBtn { text: Fz.tr("Xem thử"); onClicked: Quickshell.execDetached(["pkexec", "true"]) } }
        SRow {
            title: Fz.tr("Gửi thống kê cài đặt ẩn danh"); sub: "install/telemetry.sh"
            FToggle {
                on: page.d.telemetry !== "false"
                onToggled: (v) => { run.command = ["bash", "-c", "f=\"$1\"; mkdir -p \"$(dirname \"$f\")\"; touch \"$f\"; sed -i '/^ENABLE_TELEMETRY=/d' \"$f\"; echo \"ENABLE_TELEMETRY=$2\" >> \"$f\"", "_", Caching.stateDir + "/version", v ? "true" : "false"]; run.running = true; }
            }
        }
    }
}
