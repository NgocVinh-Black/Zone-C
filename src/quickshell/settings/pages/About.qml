import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../../"
import "../../frost"

// Giới thiệu: Zone-C version and links, hardware and system information.
Column {
    id: page
    property var app
    width: parent ? parent.width : 0

    property var d: ({})
    Process {
        running: true
        command: ["bash", "-c", "echo \"host=$(cat /sys/class/dmi/id/product_name 2>/dev/null || hostname)\"; echo \"hostname=$(hostname)\"; echo \"cpu=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)\";"
            + "echo \"gpu=$(lspci 2>/dev/null | grep -iE 'vga|3d|display' | head -1 | cut -d: -f3 | sed 's/ (rev .*)//' | xargs)\"; echo \"ram=$(awk '/MemTotal/{printf \"%.0f\", $2/1048576}' /proc/meminfo)\";"
            + "echo \"disk=$(lsblk -dbno SIZE,TYPE | awk '$2==\"disk\"{s+=$1} END{printf \"%.0f\", s/1e9}')\"; . /etc/os-release; echo \"os=$PRETTY_NAME\"; echo \"kernel=$(uname -r)\";"
            + "echo \"hypr=$(hyprctl version -j 2>/dev/null | grep -m1 '\"tag\"' | cut -d'\"' -f4)\"; echo \"up=$(cut -d. -f1 /proc/uptime)\""]
        stdout: StdioCollector { onStreamFinished: { let o = {}; this.text.split("\n").forEach(l => { let i = l.indexOf("="); if (i > 0) o[l.slice(0, i)] = l.slice(i + 1); }); page.d = o; } }
    }
    function up(s) { s = Number(s) || 0; let dd = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60); return (dd ? dd + " ngày " : "") + (h ? h + " giờ " : "") + m + " phút"; }

    Grp {
        width: parent.width
        Column {
            width: parent.width; topPadding: 28; bottomPadding: 28
            spacing: 10
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 88; height: 88; radius: 26
                gradient: Gradient { orientation: Gradient.Vertical; GradientStop { position: 0; color: Fz.s0 } GradientStop { position: 1; color: Fz.ink } }
                border.width: 1; border.color: Fz.fg(0.1)
                FIcon { anchors.centerIn: parent; name: "s-zc"; size: 62; color: Fz.acc }
            }
            FText { anchors.horizontalCenter: parent.horizontalCenter; text: "Zone-C"; px: 24; weight: Font.DemiBold }
            FText { anchors.horizontalCenter: parent.horizontalCenter; text: "v" + Updater.localVersion + " • bởi NgocVinh-Black · phái sinh từ Serpantinum · AGPL-3.0"; px: 13; color: Fz.sub }
            FText {
                anchors.horizontalCenter: parent.horizontalCenter; text: "github.com/NgocVinh-Black/Zone-C"; px: 13; color: Fz.glow
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.openUrlExternally("https://github.com/NgocVinh-Black/Zone-C") }
            }
        }
    }

    component Info: SRow {
        id: inf
        property string value
        property bool valueMono: false
        FText { text: inf.value; mono: inf.valueMono; px: 13.5; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter }
    }

    H3 { text: "Phần cứng" }
    Grp {
        width: parent.width
        Info { title: "Tên thiết bị"; value: (page.d.host || "") + (page.d.hostname ? " · " + page.d.hostname : "") }
        Info { title: "Bộ xử lý"; value: page.d.cpu || "" }
        Info { title: "Card đồ họa"; value: page.d.gpu || "" }
        Info { title: "Bộ nhớ (RAM)"; value: (page.d.ram || "") + " GB" }
        Info { title: "Dung lượng ổ đĩa"; value: (page.d.disk || "") + " GB" }
    }
    H3 { text: "Hệ thống" }
    Grp {
        width: parent.width
        Info { title: "Hệ điều hành"; value: page.d.os || "" }
        Info { title: "Kernel"; value: page.d.kernel || ""; valueMono: true }
        Info { title: "Môi trường desktop"; value: "Hyprland " + (page.d.hypr || "") + " · Quickshell" }
        Info { title: "Thời gian hoạt động"; value: page.up(page.d.up) }
    }
}
