import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../../"
import "../../frost"

// Lưu trữ: system disk usage split into system / apps / user / cache, clean-ups (pacman cache,
// orphans, trash, journal) and snapper snapshots when installed.
Column {
    id: page
    property var app
    width: parent ? parent.width : 0

    property var d: ({})
    property var parts: null
    function gb(b) { b = Number(b) || 0; return b >= 1073741824 ? (b / 1073741824).toFixed(b >= 1e10 ? 0 : 1) + " GB" : Math.round(b / 1048576) + " MB"; }
    Process {
        id: probe
        running: true
        command: ["bash", "-c", "read size used avail < <(df -B1 --output=size,used,avail / | tail -1); echo \"size=$size\"; echo \"used=$used\"; echo \"avail=$avail\";"
            + "src=$(findmnt -no SOURCE / | sed 's/\\[.*//'); dev=$(lsblk -no PKNAME \"$src\" 2>/dev/null | tail -1); echo \"model=$(lsblk -dno MODEL /dev/${dev:-x} 2>/dev/null | xargs)\"; echo \"tran=$(lsblk -dno TRAN /dev/${dev:-x} 2>/dev/null)\";"
            + "echo \"pac=$(du -sb /var/cache/pacman/pkg 2>/dev/null | cut -f1)\"; o=$(pacman -Qdtq 2>/dev/null); echo \"orph=$(echo -n \"$o\" | grep -c .)\";"
            + "[ -n \"$o\" ] && echo \"orphsz=$(pacman -Qi $o 2>/dev/null | awk -F': ' '/Installed Size/{split($2,a,\" \"); m=(a[2]==\"KiB\")?1024:(a[2]==\"MiB\")?1048576:(a[2]==\"GiB\")?1073741824:1; s+=a[1]*m} END{printf \"%d\", s}')\";"
            + "echo \"trash=$(du -sb ~/.local/share/Trash 2>/dev/null | cut -f1)\"; echo \"journal=$(journalctl --disk-usage 2>/dev/null | grep -oE '[0-9.]+[KMGT]')\";"
            + "command -v snapper >/dev/null && { echo snapper=1; pacman -Q snap-pac >/dev/null 2>&1 && echo snappac=1; echo \"last=$(snapper --no-headers --csvout list --columns number,date,description 2>/dev/null | tail -1)\"; }"]
        stdout: StdioCollector { onStreamFinished: { let o = {}; this.text.split("\n").forEach(l => { let i = l.indexOf("="); if (i > 0) o[l.slice(0, i)] = l.slice(i + 1); }); page.d = o; } }
    }
    Process {
        running: true
        command: ["bash", "-c", "s(){ timeout 25 du -sbx \"$@\" 2>/dev/null | awk '{t+=$1} END{printf \"%d\", t}'; };"
            + "echo \"sys=$(s /usr /boot /etc)\"; echo \"apps=$(s /opt /var/lib/flatpak ~/.local/share/flatpak ~/.local/share/Steam)\";"
            + "echo \"cache=$(s ~/.cache /var/cache/pacman)\"; h=$(s ~); c=$(s ~/.cache ~/.local/share/flatpak ~/.local/share/Steam); echo \"user=$((h - c))\""]
        stdout: StdioCollector { onStreamFinished: { let o = {}; this.text.split("\n").forEach(l => { let i = l.indexOf("="); if (i > 0) o[l.slice(0, i)] = Number(l.slice(i + 1)) || 0; }); page.parts = o; } }
    }
    Process { id: run; onExited: probe.running = true }
    function cmd(a) { run.command = a; run.running = true; }
    readonly property real total: Number(d.size) || 1

    Grp {
        width: parent.width
        Column {
            x: 20; topPadding: 18; bottomPadding: 18
            width: parent.width - 40
            spacing: 12
            Row {
                spacing: 10
                FText { text: (page.d.tran === "nvme" ? "NVMe SSD" : page.d.model || "Ổ đĩa hệ thống") + " · " + page.gb(page.d.size); px: 15; weight: Font.DemiBold }
                FText { anchors.baseline: parent.children[0].baseline; text: "Đã dùng " + page.gb(page.d.used) + " · trống " + page.gb(page.d.avail); px: 13.5; color: Fz.sub }
            }
            Item {
                width: parent.width; height: 14
                Rectangle { anchors.fill: parent; radius: 7; color: Fz.fg(0.08) }
                Row {
                    width: parent.width; height: 14
                    spacing: 2
                    Repeater {
                        model: page.parts ? [[page.parts.sys, Fz.tx, 1], [page.parts.apps, Fz.acc, 0.85], [page.parts.user, Fz.glow, 1], [page.parts.cache, Fz.s2, 1]] : []
                        delegate: Rectangle { required property var modelData; required property int index; width: Math.max(2, modelData[0] / page.total * (parent.width - 6)); height: 14; color: modelData[1]; opacity: modelData[2]
                                              radius: index === 0 ? 7 : 0
                                              Rectangle { visible: index === 0; anchors.right: parent.right; width: parent.width / 2; height: parent.height; color: parent.color } }
                    }
                }
            }
            Flow {
                width: parent.width
                spacing: 18
                Repeater {
                    model: page.parts ? [["Hệ thống", page.parts.sys, Fz.tx], ["Ứng dụng", page.parts.apps, Fz.acc], ["Người dùng", page.parts.user, Fz.glow], ["Bộ nhớ đệm", page.parts.cache, Fz.s2]] : [["Đang tính dung lượng…", 0, Fz.sub]]
                    delegate: Row {
                        required property var modelData
                        spacing: 6
                        Rectangle { width: 9; height: 9; radius: 2; color: modelData[2]; anchors.verticalCenter: parent.verticalCenter; visible: page.parts !== null }
                        FText { text: modelData[0] + (page.parts ? " " + page.gb(modelData[1]) : ""); px: 12.5; color: Fz.sub2 }
                    }
                }
            }
        }
    }

    H3 { text: "Dọn dẹp" }
    Grp {
        width: parent.width
        SRow { title: "Bộ nhớ đệm pacman"; sub: "pacman -Sc · " + page.gb(page.d.pac); subMono: true; FBtn { text: "Dọn"; onClicked: page.cmd(["pkexec", "pacman", "-Sc", "--noconfirm"]) } }
        SRow {
            title: "Gói mồ côi"; sub: Number(page.d.orph) > 0 ? page.d.orph + " gói · " + page.gb(page.d.orphsz) : "Không có gói mồ côi"
            FBtn { visible: Number(page.d.orph) > 0; text: "Gỡ"; onClicked: page.cmd(["pkexec", "bash", "-c", "pacman -Rns --noconfirm $(pacman -Qdtq)"]) }
        }
        SRow { title: "Thùng rác"; sub: Number(page.d.trash) > 0 ? page.gb(page.d.trash) : "Trống"; FBtn { text: "Dọn sạch"; onClicked: page.cmd(["gio", "trash", "--empty"]) } }
        SRow { title: "Nhật ký hệ thống"; sub: "journalctl · " + (page.d.journal || "–"); subMono: true; FBtn { text: "Giới hạn 200 MB"; onClicked: page.cmd(["pkexec", "journalctl", "--vacuum-size=200M"]) } }
    }

    H3 { text: "Snapshot" }
    Grp {
        width: parent.width
        SRow {
            title: "Snapshot trước mỗi lần cập nhật"; sub: page.d.snapper ? "snapper + snap-pac" : "Cần gói snapper và snap-pac (Btrfs)"
            FToggle {
                enabled: !!page.d.snapper; opacity: enabled ? 1 : 0.5
                on: !!page.d.snappac
                onToggled: (v) => page.cmd(["pkexec", "pacman", v ? "-S" : "-R", "--noconfirm", "snap-pac"])
            }
        }
        SRow {
            visible: !!page.d.snapper
            readonly property var last: (page.d.last || "").split(",")
            title: "Gần nhất"; subMono: true; sub: last[0] ? "#" + last[0] + " · " + last[1] + (last[2] ? " · " + last[2] : "") : "Chưa có snapshot"
            FBtn { text: "Khôi phục…"; onClicked: Quickshell.execDetached(["bash", "-c", Config.getSetting("launcher.terminalCommand", "kitty -e") + " bash -c 'sudo snapper list; echo; echo \"Khôi phục: sudo snapper rollback <số>\"; exec bash'"]) }
        }
    }
}
