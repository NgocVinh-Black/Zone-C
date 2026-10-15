import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../../"
import "../../frost"

// Người dùng: this account (avatar, uid, wheel), password, fingerprints, SDDM auto-login and theme,
// and the other local accounts.
Column {
    id: page
    property var app
    width: parent ? parent.width : 0

    readonly property string avatar: SystemInfo.avatarPath ? (SystemInfo.avatarPath.startsWith("file://") ? SystemInfo.avatarPath : "file://" + SystemInfo.avatarPath) : ""
    readonly property string term: Config.getSetting("launcher.terminalCommand", "kitty -e")
    property var d: ({})
    property var others: []
    Process {
        id: probe
        running: true
        command: ["bash", "-c", "echo \"uid=$(id -u)\"; echo \"groups=$(id -nG)\"; command -v fprintd-list >/dev/null && echo \"fp=$(fprintd-list \"$USER\" 2>/dev/null | grep -c ' - #')\";"
            + "echo \"auto=$(grep -rhs '^User=' /etc/sddm.conf /etc/sddm.conf.d/ 2>/dev/null | head -1 | cut -d= -f2)\"; echo \"theme=$(grep -rhs '^Current=' /etc/sddm.conf /etc/sddm.conf.d/ 2>/dev/null | head -1 | cut -d= -f2)\";"
            + "echo \"themes=$(ls /usr/share/sddm/themes 2>/dev/null | tr '\\n' ',')\";"
            + "getent passwd | awk -F: -v me=\"$USER\" '$3>=1000 && $3<60000 && $1!=me {print \"U\\t\"$1\"\\t\"$5}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let o = {}, u = [];
                this.text.split("\n").forEach(l => { if (l.indexOf("U\t") === 0) { let c = l.split("\t"); u.push({ name: c[1], full: (c[2] || "").split(",")[0] }); return; } let i = l.indexOf("="); if (i > 0) o[l.slice(0, i)] = l.slice(i + 1); });
                page.d = o; page.others = u;
            }
        }
    }
    Process { id: run; onExited: probe.running = true }
    function terminal(sh) { Quickshell.execDetached(["bash", "-c", page.term + " bash -c \"$1\"", "_", sh + "; echo; read -n1 -p 'Nhấn phím bất kỳ để đóng…'"]); }
    readonly property bool wheel: /\bwheel\b/.test(d.groups || "")
    readonly property var themes: (d.themes || "").split(",").filter(x => x)

    Grp {
        width: parent.width
        Item {
            width: parent.width; height: 112
            Rectangle { x: 20; anchors.verticalCenter: parent.verticalCenter; width: 78; height: 78; radius: 39; color: Fz.acc
                        RoundImage { anchors.centerIn: parent; width: 72; height: 72; radius: 36; source: page.avatar } }
            Column {
                x: 20 + 78 + 18; anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                FText { text: SystemInfo.username; px: 18; weight: Font.DemiBold }
                FText { width: page.width - 116 - 180; elide: Text.ElideMiddle; text: "uid " + (page.d.uid || "") + " · " + Quickshell.env("HOME"); mono: true; px: 12.5; color: Fz.sub }
                Item { width: 1; height: 4 }
                FChip { kind: page.wheel ? "acc" : ""; text: page.wheel ? "Quản trị (wheel)" : "Tiêu chuẩn" }
            }
            FBtn { anchors.right: parent.right; anchors.rightMargin: 20; anchors.verticalCenter: parent.verticalCenter; text: "Đổi mật khẩu"; onClicked: page.terminal("passwd") }
        }
    }

    H3 { text: "Đăng nhập" }
    Grp {
        width: parent.width
        SRow {
            icon: "s-finger"; title: "Vân tay"
            sub: page.d.fp === undefined ? "Cần gói fprintd" : Number(page.d.fp) > 0 ? "fprintd · " + page.d.fp + " ngón đã đăng ký" : "fprintd · chưa đăng ký"
            FBtn { enabled: page.d.fp !== undefined; opacity: enabled ? 1 : 0.5; text: "Quản lý"; onClicked: page.terminal("fprintd-enroll") }
        }
        SRow {
            title: "Tự động đăng nhập"; sub: "Bỏ qua SDDM"
            FToggle {
                on: page.d.auto === SystemInfo.username
                onToggled: (v) => { run.command = ["pkexec", "bash", "-c", v ? "mkdir -p /etc/sddm.conf.d && printf '[Autologin]\\nUser=%s\\nSession=hyprland\\n' \"$1\" > /etc/sddm.conf.d/50-zone-c-autologin.conf" : "rm -f /etc/sddm.conf.d/50-zone-c-autologin.conf", "_", SystemInfo.username]; run.running = true; }
            }
        }
        SRow {
            title: "Theme SDDM"
            FSelect {
                enabled_: page.themes.length > 0
                options: page.themes.length ? page.themes : ["Không có theme"]
                current: Math.max(0, page.themes.indexOf(page.d.theme))
                onPicked: (i) => { run.command = ["pkexec", "bash", "-c", "mkdir -p /etc/sddm.conf.d && printf '[Theme]\\nCurrent=%s\\n' \"$1\" > /etc/sddm.conf.d/60-zone-c-theme.conf", "_", page.themes[i]]; run.running = true; }
            }
        }
    }

    H3 { text: "Người dùng khác" }
    Grp {
        width: parent.width
        Repeater {
            model: page.others
            delegate: SRow {
                required property var modelData
                iconText: modelData.name.charAt(0).toUpperCase(); title: modelData.full || modelData.name; sub: modelData.name
                FBtn { text: "Quản lý"; onClicked: page.terminal("echo 'Nhóm của " + modelData.name + ":'; id -nG " + modelData.name + "; echo; echo 'Đổi mật khẩu: sudo passwd " + modelData.name + "'; echo 'Xóa: sudo userdel -r " + modelData.name + "'; exec bash") }
            }
        }
        SRow { visible: page.others.length === 0; title: "Chỉ có tài khoản của bạn" }
        SRow { title: "Tài khoản khách"; sub: "Không có trên Arch mặc định"; FToggle { enabled: false; opacity: 0.5 } }
        SRow {
            title: "Thêm người dùng…"
            FInput { id: newUser; width: 160; height: 36; placeholder: "tên đăng nhập" }
            FBtn { icon: "s-plus"; iconSize: 14; text: "Thêm"; onClicked: { let n = newUser.text.trim().toLowerCase().replace(/[^a-z0-9_-]/g, ""); if (n) page.terminal("sudo useradd -m -G users " + n + " && sudo passwd " + n); newUser.text = ""; } }
        }
    }
}
