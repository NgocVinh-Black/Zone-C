import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../../"
import "../../frost"

// Máy in: printers and their state (CUPS lpstat), the print queue with cancel / hold, test page,
// default printer, paper size and duplex defaults (lpoptions), and the CUPS web admin.
Column {
    id: page
    property var app
    width: parent ? parent.width : 0

    property bool hasCups: true
    property var printers: []        // { name, state, def, uri }
    property var jobs: []            // { id, printer, user, size, state }
    property var opts: ({})
    Process {
        id: probe
        running: true
        command: ["bash", "-c", "command -v lpstat >/dev/null || { echo NOCUPS; exit; }; d=$(lpstat -d 2>/dev/null | sed 's/.*: //');"
            + "lpstat -p 2>/dev/null | awk -v d=\"$d\" '/^printer/{s=($3==\"is\")?$4:$3; gsub(/\\./,\"\",s); print \"P\\t\"$2\"\\t\"s\"\\t\"($2==d)}';"
            + "lpstat -v 2>/dev/null | sed -n 's/^device for \\([^:]*\\): \\(.*\\)/U\\t\\1\\t\\2/p';"
            + "lpstat -o 2>/dev/null | awk '{print \"J\\t\"$1\"\\t\"$2\"\\t\"$3}';"
            + "lpoptions 2>/dev/null | tr ' ' '\\n' | grep -E '^(media|sides)=' | sed 's/^/O\\t/; s/=/\\t/'"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.indexOf("NOCUPS") !== -1) { page.hasCups = false; return; }
                let ps = [], js = [], o = {}, uri = {};
                this.text.split("\n").forEach(l => {
                    let c = l.split("\t");
                    if (c[0] === "P") ps.push({ name: c[1], state: c[2], def: c[3] === "1" });
                    else if (c[0] === "U") uri[c[1]] = c[2];
                    else if (c[0] === "J") js.push({ id: c[1], user: c[2], size: c[3] });
                    else if (c[0] === "O") o[c[1]] = c[2];
                });
                ps.forEach(p => p.uri = uri[p.name] || "");
                page.printers = ps; page.jobs = js; page.opts = o;
            }
        }
    }
    Timer { interval: 4000; repeat: true; running: page.hasCups; onTriggered: probe.running = true }
    Process { id: run; onExited: probe.running = true }
    function cmd(a) { run.command = a; run.running = true; }
    function conn(uri) { return /^usb:/.test(uri) ? "USB" : /^ipps?:|^dnssd:/.test(uri) ? "Wi-Fi · IPP Everywhere" : /^cups-pdf:/.test(uri) ? "cups-pdf" : uri.split(":")[0].toUpperCase(); }

    Grp {
        visible: !page.hasCups
        width: parent.width
        SRow {
            icon: "s-printers"; title: Fz.tr("Chưa cài CUPS"); sub: Fz.tr("Cần gói cups để in và quản lý máy in")
            FBtn { kind: "pri"; text: Fz.tr("Cài đặt"); onClicked: Quickshell.execDetached(["bash", "-c", (Config.getSetting("launcher.terminalCommand", "kitty -e")) + Fz.tr(" bash -c 'sudo pacman -S --needed cups cups-pdf && sudo systemctl enable --now cups.socket; read -n1 -p \"Xong. Nhấn phím bất kỳ…\"'")]) }
        }
    }

    Grp {
        visible: page.hasCups
        width: parent.width
        Repeater {
            model: page.printers
            delegate: SRow {
                required property var modelData
                readonly property bool virt: /^cups-pdf:/.test(modelData.uri)
                icon: "s-printers"; iconOn: modelData.def
                title: modelData.name.replace(/_/g, " "); sub: page.conn(modelData.uri) + (modelData.def ? Fz.tr(" · Mặc định") : "")
                FChip { kind: virt ? "" : modelData.state === "idle" || modelData.state === "printing" ? "ok" : "bad"; anchors.verticalCenter: parent.verticalCenter
                        text: virt ? Fz.tr("Ảo") : modelData.state === "idle" ? Fz.tr("Sẵn sàng") : modelData.state === "printing" ? Fz.tr("Đang in") : Fz.tr("Ngoại tuyến") }
                FBtn {
                    visible: !virt
                    text: modelData.def ? Fz.tr("In trang thử") : Fz.tr("Đặt mặc định")
                    onClicked: modelData.def ? page.cmd(["lp", "-d", modelData.name, "/usr/share/cups/data/testprint"]) : page.cmd(["lpoptions", "-d", modelData.name])
                }
            }
        }
        SRow {
            title: Fz.tr("Thêm máy in…"); sub: Fz.tr("Tự tìm máy in trong mạng (Avahi) hoặc nhập địa chỉ")
            FBtn { kind: "pri"; icon: "s-plus"; iconSize: 14; text: Fz.tr("Thêm"); onClicked: Qt.openUrlExternally("http://localhost:631/admin/") }
        }
    }

    H3 { visible: page.hasCups; text: Fz.tr("Hàng đợi in") }
    Grp {
        visible: page.hasCups
        width: parent.width
        Repeater {
            model: page.jobs
            delegate: SRow {
                required property var modelData
                title: modelData.id; titleMono: true; titleSize: 13; sub: modelData.user + " · " + Math.round(modelData.size / 1024) + " KB"
                FBtn { height: 30; fontSize: 12; text: Fz.tr("Tạm dừng"); onClicked: page.cmd(["lp", "-i", modelData.id, "-H", "hold"]) }
                FBtn { height: 30; fontSize: 12; kind: "danger"; text: Fz.tr("Hủy"); onClicked: page.cmd(["cancel", modelData.id]) }
            }
        }
        SRow { visible: page.jobs.length === 0; title: Fz.tr("Không có lệnh in nào") }
    }

    H3 { visible: page.hasCups; text: Fz.tr("Mặc định") }
    Grp {
        visible: page.hasCups
        width: parent.width
        SRow {
            title: Fz.tr("Khổ giấy")
            FSelect { options: ["A4", "A5", "Letter"]; readonly property var values: ["A4", "A5", "Letter"]
                      current: Math.max(0, values.indexOf(page.opts.media || "A4")); onPicked: (i) => page.cmd(["lpoptions", "-o", "media=" + values[i]]) }
        }
        SRow {
            title: Fz.tr("In hai mặt")
            FSelect { options: [Fz.tr("Một mặt"), Fz.tr("Hai mặt · lật cạnh dài")]; readonly property var values: ["one-sided", "two-sided-long-edge"]
                      current: Math.max(0, values.indexOf(page.opts.sides || "one-sided")); onPicked: (i) => page.cmd(["lpoptions", "-o", "sides=" + values[i]]) }
        }
        SRow { title: Fz.tr("Quản trị CUPS nâng cao"); sub: "http://localhost:631"; subMono: true; FBtn { text: Fz.tr("Mở"); onClicked: Qt.openUrlExternally("http://localhost:631") } }
    }
}
