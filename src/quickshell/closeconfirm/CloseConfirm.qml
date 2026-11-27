import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../"
import "../frost"

// Close confirmation of the Frost design (Dialogs.dc.html). smart-close (Super+Q) calls ask();
// apps ticked "Không hỏi lại" close straight away (closeconfirm.skip in settings).
PanelWindow {
    id: root

    property bool active: false
    property string winAddress: ""
    property string winTitle: ""
    property string winClass: ""
    property var proc: null              // { pid, etime, cmd } of the window's foreground process
    property bool dontAsk: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-closeconfirm"
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    visible: active
    color: "transparent"

    readonly property var skip: { let c = Config.getSetting("closeconfirm", {}); return (c && c.skip) ? c.skip : []; }
    readonly property string appName: {
        let m = { "foot": "Foot", "kitty": "kitty", "google-chrome": "Google Chrome", "code": "VS Code", "org.gnome.Nautilus": Fz.tr("Tệp"), "ViberPC": "Viber" };
        return m[winClass] || (winClass ? winClass.charAt(0).toUpperCase() + winClass.slice(1) : (winTitle || Fz.tr("cửa sổ này")));
    }
    readonly property bool isTerminal: /foot|kitty|alacritty|wezterm|konsole|terminal/i.test(winClass)
    readonly property bool risky: proc !== null && /pacman|yay|paru|pkexec|sudo|dd |mkfs|rsync|git /.test(proc.cmd)

    function ask(address, title, cls) {
        if (skip.indexOf(cls) !== -1) { closeNow(address); return; }
        winAddress = address; winTitle = title; winClass = cls;
        proc = null; dontAsk = false;
        Hyprland.refreshToplevels();
        probe.command = ["bash", "-c", root.probeScript, "_", address];
        probe.running = true;
        active = true;
        focusTimer.restart();
    }
    function cancel() { active = false; }
    function closeNow(address) {
        Quickshell.execDetached(["hyprctl", "dispatch", 'hl.dsp.window.close({ window = "address:' + address + '" })']);
    }
    function confirm() {
        if (dontAsk && winClass !== "") {
            let c = Object.assign({}, Config.getSetting("closeconfirm", {}));
            c.skip = (c.skip || []).concat([winClass]);
            Config.setSetting("closeconfirm", c);
        }
        if (winAddress !== "") closeNow(winAddress);
        active = false;
    }

    // deepest descendant that is not a shell: "pid|elapsed|command"
    readonly property string probeScript: "p=$(hyprctl clients -j | jq -r --arg a \"$1\" '.[] | select(.address == $a) | .pid'); [ -n \"$p\" ] || exit 0; best=''; walk(){ for c in $(ps -o pid= --ppid \"$1\"); do n=$(ps -o comm= -p $c); case \"$n\" in bash|zsh|fish|sh|dash) ;; *) best=$c ;; esac; walk $c; done; }; walk $p; [ -n \"$best\" ] && ps -o pid=,etime=,args= -p $best | awk '{pid=$1; et=$2; $1=\"\"; $2=\"\"; sub(/^ +/,\"\"); print pid \"|\" et \"|\" $0}'"
    Process {
        id: probe
        stdout: StdioCollector {
            onStreamFinished: {
                let p = this.text.trim().split("|");
                root.proc = p.length >= 3 ? { pid: p[0], etime: p[1].replace(/^0(\d:)/, "$1"), cmd: p.slice(2).join("|") } : null;
            }
        }
    }

    IpcHandler {
        target: "closeconfirm"
        function ask(address: string, title: string, cls: string): void { root.ask(address, title, cls); }
        function cancel(): void { root.cancel(); }
        function isOpen(): bool { return root.active; }
    }
    Timer { id: focusTimer; interval: 40; onTriggered: keys.forceActiveFocus() }
    Item {
        id: keys
        Keys.onEscapePressed: root.cancel()
        Keys.onReturnPressed: root.confirm()
    }

    Rectangle { anchors.fill: parent; color: Fz.scrimNight; MouseArea { anchors.fill: parent; onClicked: root.cancel() } }

    Solid {
        anchors.centerIn: parent
        width: 520
        height: body.implicitHeight + 52
        radius: 28
        MouseArea { anchors.fill: parent }
        Column {
            id: body
            x: 26; y: 26
            width: parent.width - 52
            spacing: 18

            Row {
                width: parent.width
                spacing: 16
                Rectangle {
                    width: 52; height: 52; radius: 16; color: Fz.yellowA(0.14)
                    FIcon { anchors.centerIn: parent; name: "dg-warn"; size: 26; color: Fz.yellow }
                }
                Column {
                    width: parent.width - 52 - 16
                    spacing: 6
                    FText { text: Fz.tr("Đóng ") + root.appName + "?"; px: 20; weight: Font.DemiBold }
                    FText {
                        width: parent.width; wrapMode: Text.Wrap; css: 1.25; px: 14; color: Fz.sub2
                        text: root.proc
                            ? (root.isTerminal ? "Terminal" : root.appName) + Fz.tr(" đang chạy một tiến trình. Đóng bây giờ sẽ dừng tiến trình") + (root.risky ? Fz.tr(" và có thể làm hỏng lần cập nhật.") : ".")
                            : Fz.tr("Nội dung chưa lưu trong ") + (root.winTitle || root.appName) + Fz.tr(" có thể bị mất.")
                    }
                }
            }
            Card {
                visible: root.proc !== null
                width: parent.width; height: 46
                Row {
                    x: 14; anchors.verticalCenter: parent.verticalCenter
                    spacing: 12
                    FIcon { name: "dg-terminal"; color: Fz.acc; anchors.verticalCenter: parent.verticalCenter }
                    FText { width: body.width - 28 - 17 - 24 - chip.width; elide: Text.ElideRight; mono: true; text: root.proc ? root.proc.cmd : ""; px: 13; anchors.verticalCenter: parent.verticalCenter }
                    FChip { id: chip; kind: "warn"; text: root.proc ? "PID " + root.proc.pid + " · " + root.proc.etime : ""; anchors.verticalCenter: parent.verticalCenter }
                }
            }
            Item {
                width: askRow.implicitWidth; height: 20
                Row {
                    id: askRow
                    spacing: 10
                    Rectangle {
                        width: 20; height: 20; radius: 6
                        color: root.dontAsk ? Fz.acc : "transparent"
                        border.width: root.dontAsk ? 0 : 1.5; border.color: Fz.s2
                        FIcon { anchors.centerIn: parent; name: "dg-check"; size: 14; color: Fz.ink; opacity: root.dontAsk ? 1 : 0 }
                    }
                    FText { text: Fz.tr("Không hỏi lại với ") + root.appName; px: 13.5; color: Fz.sub2; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.dontAsk = !root.dontAsk }
            }
            Row {
                anchors.right: parent.right
                spacing: 8
                FBtn { height: 42; padX: 18; text: Fz.tr("Hủy · Esc"); onClicked: root.cancel() }
                FBtn { height: 42; padX: 18; kind: "danger"; text: Fz.tr("Đóng ngay"); onClicked: root.confirm() }
            }
        }
    }
}
