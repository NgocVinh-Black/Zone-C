import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../../"
import "../../frost"

// Ứng dụng: default browser / terminal / editor / file manager (xdg-mime, xdg-settings), autostart
// entries (~/.config/autostart) and the biggest installed packages (remove opens the App store flow).
Column {
    id: page
    property var app
    width: parent ? parent.width : 0

    readonly property var entries: DesktopEntries.applications ? (DesktopEntries.applications.values || []) : []
    function byCat(c) { return entries.filter(e => !e.noDisplay && (e.categories || []).indexOf(c) !== -1).sort((a, b) => a.name.localeCompare(b.name)); }
    readonly property var browsers: byCat("WebBrowser")
    readonly property var terminals: byCat("TerminalEmulator")
    readonly property var editors: byCat("TextEditor")
    readonly property var fileManagers: byCat("FileManager")

    property var defs: ({})
    property var autostart: []
    property var pkgs: []
    property int pkgCount: 0
    Process {
        id: probe
        running: true
        command: ["bash", "-c", "echo \"browser=$(xdg-settings get default-web-browser 2>/dev/null)\"; echo \"files=$(xdg-mime query default inode/directory 2>/dev/null)\"; echo \"text=$(xdg-mime query default text/plain 2>/dev/null)\";"
            + "echo \"term=$(head -1 ~/.config/xdg-terminals.list 2>/dev/null)\";"
            + "for f in ~/.config/autostart/*.desktop; do [ -f \"$f\" ] || continue; n=$(grep -m1 '^Name=' \"$f\" | cut -d= -f2-); c=$(grep -m1 '^Comment=' \"$f\" | cut -d= -f2-); h=$(grep -m1 -i '^Hidden=' \"$f\" | cut -d= -f2-); echo \"A\t$f\t$n\t$c\t$h\"; done;"
            + "echo \"count=$(pacman -Qq | wc -l)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                let o = {}, a = [];
                this.text.split("\n").forEach(l => {
                    if (l.indexOf("A\t") === 0) { let c = l.split("\t"); a.push({ file: c[1], name: c[2] || c[1].split("/").pop(), desc: c[3] || "", on: (c[4] || "").toLowerCase() !== "true" }); return; }
                    let i = l.indexOf("="); if (i > 0) o[l.slice(0, i)] = l.slice(i + 1);
                });
                page.defs = o; page.autostart = a; page.pkgCount = Number(o.count) || 0;
            }
        }
    }
    Process {
        running: true
        command: ["python3", Quickshell.shellDir + "/apps/pkg.py", "installed"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let mb = s => { let m = (s || "").match(/([\d.]+)\s*(KB|MB|GB)/); return m ? parseFloat(m[1]) * ({ KB: 1 / 1024, MB: 1, GB: 1024 })[m[2]] : 0; };
                    page.pkgs = JSON.parse(this.text).data.filter(p => p.size).sort((x, y) => mb(y.size) - mb(x.size)).slice(0, 5);
                } catch (e) {}
            }
        }
    }
    Process { id: run; onExited: probe.running = true }
    function idOf(e) { return (e.id || "").replace(/\.desktop$/, "") + ".desktop"; }
    function setDefault(kind, e) {
        let id = idOf(e);
        if (kind === "browser") run.command = ["xdg-settings", "set", "default-web-browser", id];
        else if (kind === "files") run.command = ["xdg-mime", "default", id, "inode/directory"];
        else if (kind === "text") run.command = ["xdg-mime", "default", id, "text/plain"];
        else {
            run.command = ["bash", "-c", "mkdir -p ~/.config && printf '%s\\n' \"$1\" > ~/.config/xdg-terminals.list", "_", id];
            let exec = (e.execString || e.command && e.command.join(" ") || "").split(" ")[0];
            if (exec) Config.setSetting("launcher.terminalCommand", exec + " -e");
        }
        run.running = true;
    }
    function setAutostart(a, on) {
        run.command = ["bash", "-c", "f=\"$1\"; sed -i '/^Hidden=/Id' \"$f\"; [ \"$2\" = off ] && echo 'Hidden=true' >> \"$f\"; true", "_", a.file, on ? "on" : "off"];
        run.running = true;
    }

    component DefaultRow: SRow {
        id: dr
        property string kind
        property var list: []
        property string cur: ""
        FSelect {
            options: dr.list.length ? dr.list.map(e => e.name) : [Fz.tr("Chưa có ứng dụng")]
            current: Math.max(0, dr.list.findIndex(e => page.idOf(e) === dr.cur))
            onPicked: (i) => { if (dr.list[i]) page.setDefault(dr.kind, dr.list[i]); }
        }
    }

    H3 { first: true; text: Fz.tr("Ứng dụng mặc định · mimeapps.list") }
    Grp {
        width: parent.width
        DefaultRow { title: Fz.tr("Trình duyệt"); kind: "browser"; list: page.browsers; cur: page.defs.browser || "" }
        DefaultRow { title: "Terminal"; kind: "term"; list: page.terminals; cur: page.defs.term || "" }
        DefaultRow { title: Fz.tr("Trình soạn thảo"); kind: "text"; list: page.editors; cur: page.defs.text || "" }
        DefaultRow { title: Fz.tr("Quản lý tệp"); kind: "files"; list: page.fileManagers; cur: page.defs.files || "" }
    }

    H3 { text: Fz.tr("Khởi động cùng hệ thống") }
    Grp {
        width: parent.width
        Repeater {
            model: page.autostart
            delegate: SRow {
                required property var modelData
                title: modelData.name; sub: modelData.desc
                FToggle { on: modelData.on; onToggled: (v) => page.setAutostart(modelData, v) }
            }
        }
        SRow { visible: page.autostart.length === 0; title: Fz.tr("Chưa có ứng dụng tự khởi động"); sub: "~/.config/autostart"; subMono: true }
    }

    H3 { text: Fz.tr("Đã cài đặt · ") + page.pkgCount + Fz.tr(" gói") }
    Grp {
        width: parent.width
        Repeater {
            model: page.pkgs
            delegate: SRow {
                required property var modelData
                icon: "s-box"; title: modelData.name; sub: modelData.name + " " + modelData.version; subMono: true
                FChip { text: modelData.src; anchors.verticalCenter: parent.verticalCenter }
                FText { width: 64; horizontalAlignment: Text.AlignRight; text: modelData.size; px: 13.5; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter }
                FBtn { text: Fz.tr("Gỡ"); onClicked: Fz.open("appstore", "installed") }
            }
        }
    }
}
