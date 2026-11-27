import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Networking
import "../"
import "../frost"

// Wi-Fi password dialog of the Pairing artboard (right): opened by Fz.askWifi(net) from the network
// panel or Settings → Wi-Fi. Connects through Quickshell (the password never lands on a command line),
// then applies "auto connect" / "metered" to the saved connection with nmcli.
PanelWindow {
    id: win
    readonly property var net: Fz.wifiAsk
    property bool busy: false
    property string error: ""
    property bool autoConnect: true
    property bool metered: false
    visible: net !== null

    WlrLayershell.namespace: "zone-c-wifi-password"   // no compositor blur behind the night scrim
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    readonly property string ssid: net ? net.name : ""
    readonly property string sec: {
        let s = net ? net.security : 0;
        return ({ 1: "WEP", 2: "WPA", 3: "WPA2", 4: "WPA3", 5: "WPA2/WPA3", 6: "WPA2-Enterprise", 7: "OWE" })[s] || "";
    }
    // WPA keys are 8–63 characters; WEP has its own lengths, so only WPA gets the hint
    readonly property bool tooShort: sec.indexOf("WPA") !== -1 && pw.text.length > 0 && pw.text.length < 8

    onNetChanged: {
        busy = false; error = ""; autoConnect = true; metered = false;
        pw.text = ""; pw.reveal = false;
        if (net) focusTimer.restart();
    }
    Timer { id: focusTimer; interval: 50; onTriggered: pw.input.forceActiveFocus() }

    function close() { Fz.wifiAsk = null; }
    function submit() {
        if (!net || busy || pw.text === "" || tooShort) return;
        error = ""; busy = true;
        net.connectWithPsk(pw.text);
        failTimer.restart();
    }
    Connections {
        target: win.net
        function onConnectionFailed(reason) {
            if (!win.busy) return;
            win.busy = false; failTimer.stop();
            win.error = Fz.tr("Sai mật khẩu hoặc không kết nối được. Thử lại.");
            pw.text = ""; pw.input.forceActiveFocus();
        }
        function onConnectedChanged() {
            if (!win.busy || !win.net.connected) return;
            failTimer.stop();
            if (!win.autoConnect || win.metered)
                Quickshell.execDetached(["nmcli", "connection", "modify", "id", win.ssid,
                                         "connection.autoconnect", win.autoConnect ? "yes" : "no",
                                         "connection.metered", win.metered ? "yes" : "no"]);
            win.close();
        }
    }
    // NetworkManager gives up on its own after ~45 s; don't leave the button spinning forever
    Timer {
        id: failTimer; interval: 60000
        onTriggered: { win.busy = false; win.error = Fz.tr("Hết thời gian chờ kết nối. Thử lại."); }
    }

    // `.scrim.night`
    Rectangle { anchors.fill: parent; color: Fz.scrimNight
        MouseArea { anchors.fill: parent; onClicked: if (!win.busy) win.close() } }

    Solid {
        anchors.centerIn: parent
        width: 520
        height: body.implicitHeight + 56
        radius: 28
        MouseArea { anchors.fill: parent }   // clicks inside don't reach the scrim

        Column {
            id: body
            x: 28; y: 28
            width: parent.width - 56
            spacing: 18

            Row {
                spacing: 14
                Ico { width: 52; height: 52; radius: 16; on: true; icon: "p-wifi"; iconSize: 24; anchors.verticalCenter: parent.verticalCenter }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    FText { width: body.width - 66; elide: Text.ElideRight; text: Fz.tr("Kết nối ") + win.ssid; px: 20; weight: Font.DemiBold }
                    FText { text: win.sec ? Fz.tr("Mạng yêu cầu mật khẩu ") + win.sec : Fz.tr("Mạng yêu cầu mật khẩu"); px: 13.5; color: Fz.sub2 }
                }
            }

            Column {
                width: parent.width
                spacing: 6
                FText { text: Fz.tr("Mật khẩu"); px: 13; color: Fz.sub }
                Row {
                    width: parent.width
                    spacing: 8
                    FInput {
                        id: pw
                        width: parent.width - 8 - 46; height: 46
                        password: true
                        border.color: win.error !== "" ? Fz.red : (pw.input.activeFocus ? Fz.glow : Fz.line2)
                        onAccepted: win.submit()
                    }
                    FIconBtn { width: 46; height: 46; radius: 12; icon: "p-eye"; on: pw.reveal; label: Fz.tr("Hiện mật khẩu"); onClicked: pw.reveal = !pw.reveal }
                }
                FText { visible: win.tooShort; text: Fz.tr("Mật khẩu WPA2 cần ít nhất 8 ký tự."); px: 12.5; color: Fz.yellow }
                FText { visible: win.error !== ""; width: parent.width; wrapMode: Text.Wrap; text: win.error; px: 12.5; color: Fz.red }
            }

            Grp {
                width: parent.width
                GRow {
                    Item {
                        width: parent.width; height: 36
                        Lbl { anchors.verticalCenter: parent.verticalCenter; width: parent.width - 60; title: Fz.tr("Tự kết nối") }
                        FToggle { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; on: win.autoConnect; onToggled: (v) => win.autoConnect = v }
                    }
                }
                GRow {
                    Item {
                        width: parent.width; height: 36
                        Lbl { anchors.verticalCenter: parent.verticalCenter; width: parent.width - 60; title: Fz.tr("Mạng tính phí"); sub: Fz.tr("Hạn chế tải nền") }
                        FToggle { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; on: win.metered; onToggled: (v) => win.metered = v }
                    }
                }
            }

            Row {
                anchors.right: parent.right
                spacing: 8
                FBtn { height: 40; text: Fz.tr("Hủy"); onClicked: win.close() }
                FBtn {
                    height: 40; kind: "pri"
                    text: win.busy ? Fz.tr("Đang kết nối…") : Fz.tr("Kết nối")
                    opacity: pw.text === "" || win.tooShort ? 0.5 : 1
                    onClicked: win.submit()
                }
            }
        }
    }

    Shortcut { sequence: "Escape"; enabled: win.visible; onActivated: win.close() }
}
