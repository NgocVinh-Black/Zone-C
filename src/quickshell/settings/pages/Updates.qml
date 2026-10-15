import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../../"
import "../../frost"

// Cập nhật: pending pacman / AUR / Flatpak updates (pkg.py), update everything in a terminal,
// the Zone-C version and the update preferences.
Column {
    id: page
    property var app
    width: parent ? parent.width : 0

    readonly property var pkgs: app ? app.updatesList : []
    readonly property bool includeAur: Config.getSetting("updates.aur", true) !== false
    readonly property var shown: pkgs.filter(p => includeAur || p.src !== "AUR")
    property bool running: false
    property double checkedAt: Date.now()
    readonly property string term: Config.getSetting("launcher.terminalCommand", "kitty -e")
    function updateAll() {
        let sh = (page.includeAur ? "if command -v yay >/dev/null; then yay -Syu; else sudo pacman -Syu; fi" : "sudo pacman -Syu") + "; command -v flatpak >/dev/null && flatpak update -y; echo; read -n1 -p 'Xong. Nhấn phím bất kỳ để đóng…'";
        Quickshell.execDetached(["bash", "-c", page.term + " bash -c \"$1\"", "_", sh]);
        page.running = true; doneCheck.restart();
    }
    Timer { id: doneCheck; interval: 20000; repeat: true; onTriggered: { page.app.recheckUpdates(); if (page.shown.length === 0) { stop(); page.running = false; } } }
    Timer { interval: 60000; repeat: true; running: true; onTriggered: page.checkedAt = page.checkedAt }
    function ago() { let m = Math.round((Date.now() - checkedAt) / 60000); return m < 1 ? "vừa xong" : m + " phút trước"; }

    Grp {
        width: parent.width
        Item {
            width: parent.width; height: 84
            Rectangle { x: 20; anchors.verticalCenter: parent.verticalCenter; width: 48; height: 48; radius: 14; color: Fz.acc
                        FIcon { anchors.centerIn: parent; name: "s-box"; size: 24; color: Fz.ink } }
            Column {
                x: 20 + 48 + 16; anchors.verticalCenter: parent.verticalCenter
                FText { text: page.running ? "Đang cập nhật…" : page.shown.length ? page.shown.length + " bản cập nhật có sẵn" : "Hệ thống đã được cập nhật"; px: 16; weight: Font.DemiBold }
                FText { text: page.running ? "Đang chạy trong terminal · đừng tắt máy" : "Kiểm tra " + page.ago(); px: 13; color: Fz.sub }
            }
            Row {
                anchors.right: parent.right; anchors.rightMargin: 20; anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                FBtn { text: "Kiểm tra lại"; onClicked: { page.app.recheckUpdates(); page.checkedAt = Date.now(); } }
                FBtn { kind: "pri"; visible: page.shown.length > 0; text: "Cập nhật tất cả"; onClicked: page.updateAll() }
            }
        }
    }

    H3 { visible: page.shown.length > 0; text: "Gói cần cập nhật" }
    Grp {
        visible: page.shown.length > 0
        width: parent.width
        Repeater {
            model: page.shown.slice(0, 40)
            delegate: SRow {
                required property var modelData
                minH: 46; title: modelData.name; titleMono: true; titleSize: 13.5
                FText { textFormat: Text.StyledText; text: (modelData.old || "") + " → <b><font color=\"" + Fz.tx + "\">" + modelData.version + "</font></b>"; mono: true; px: 12.5; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter }
                FChip { width: 60; text: modelData.src === "pacman" ? "repo" : modelData.src; anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }

    H3 { text: "Zone-C" }
    Grp {
        width: parent.width
        SRow {
            title: "Zone-C shell"; sub: "v" + Updater.localVersion + (Updater.remoteVersion ? " · bản mới nhất v" + Updater.remoteVersion : ""); subMono: true
            FChip { kind: Updater.updateAvailable ? "warn" : "ok"; text: Updater.updateAvailable ? "Có bản mới" : "Mới nhất"; anchors.verticalCenter: parent.verticalCenter }
            FBtn { visible: Updater.updateAvailable; kind: "pri"; text: "Cập nhật"; onClicked: Quickshell.execDetached(["bash", "-c", page.term + " zone-c update"]) }
        }
        SRow { title: "Bao gồm gói AUR"; sub: "qua yay"; CfgToggle { key: "updates.aur"; def: true } }
        SRow { title: "Tự kiểm tra cập nhật"; CfgSelect { key: "updates.interval"; def: "daily"; options: ["Hằng ngày", "Hằng tuần"]; values: ["daily", "weekly"] } }
    }
}
