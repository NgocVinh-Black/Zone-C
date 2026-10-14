import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Bluetooth
import "../"
import "../frost"

// Bluetooth pairing request of the Pairing artboard, driven by the bluez agent (BtAgent).
PanelWindow {
    id: win
    readonly property var req: BtAgent.request
    property string doneName: ""
    property string doneAddress: ""
    visible: BtAgent.active || doneName !== ""

    WlrLayershell.namespace: "zone-c-pairing"   // no compositor blur behind the night scrim
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    readonly property var device: {
        let a = Bluetooth.defaultAdapter;
        let addr = req ? req.address : doneAddress;
        if (!a || !a.devices || !addr) return null;
        return (a.devices.values || []).find(d => d.address === addr) || null;
    }
    readonly property string devName: req ? (req.name || req.address) : doneName
    readonly property string devIcon: {
        let i = device ? (device.icon || "").toLowerCase() : "";
        if (i.indexOf("phone") !== -1) return "p-phone";
        if (i.indexOf("head") !== -1) return "n-head";
        if (i.indexOf("mouse") !== -1) return "n-mouse";
        if (i.indexOf("keyboard") !== -1) return "n-kbd";
        if (i.indexOf("audio") !== -1) return "n-spk";
        return "p-phone";
    }
    readonly property string code: req && req.passkey !== undefined ? String(req.passkey).padStart(6, "0") : ""

    function accept() {
        if (!req) return;
        let r = req;
        BtAgent.respond(true, r.type === "pin" || r.type === "passkey" ? input.text : undefined);
        if (r.type !== "display" && r.type !== "authorize") { doneName = r.name || r.address; doneAddress = r.address; }
    }
    function reject() { BtAgent.respond(false); doneName = ""; }

    // `.scrim.night`
    Rectangle { anchors.fill: parent; color: Fz.scrimNight }

    Solid {
        id: dialog
        anchors.centerIn: parent
        width: 520
        height: body.implicitHeight + 56
        radius: 28

        Column {
            id: body
            x: 28; y: 28
            width: parent.width - 56
            spacing: 18

            // ---- request ----
            Row {
                visible: !!win.req
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 14
                Ico { width: 56; height: 56; radius: 18; on: true; icon: "p-bt"; iconSize: 26; anchors.verticalCenter: parent.verticalCenter }
                Row {
                    spacing: 4; anchors.verticalCenter: parent.verticalCenter
                    Repeater { model: [1, 0.6, 0.3]; delegate: Rectangle { required property var modelData; width: 8; height: 8; radius: 4; color: Fz.acc; opacity: modelData } }
                }
                Ico { width: 56; height: 56; radius: 18; icon: win.devIcon; iconSize: 26; anchors.verticalCenter: parent.verticalCenter }
            }
            Column {
                visible: !!win.req
                width: parent.width
                spacing: 6
                FText {
                    width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
                    text: win.req && win.req.type === "authorize" ? "Cho phép " + win.devName + " kết nối?" : "Ghép nối với " + win.devName + "?"
                    px: 20; weight: Font.DemiBold
                }
                FText {
                    width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
                    color: Fz.sub2; px: 14
                    text: !win.req ? "" : win.req.type === "confirm" ? "Kiểm tra mã này trùng với mã trên " + (win.devIcon === "p-phone" ? "điện thoại" : "thiết bị") + "."
                        : win.req.type === "display" ? "Nhập mã này trên " + win.devName + " rồi nhấn Enter."
                        : (win.req.type === "pin" || win.req.type === "passkey") ? "Nhập mã PIN hiển thị trên " + win.devName + "."
                        : "Thiết bị muốn dùng một dịch vụ Bluetooth trên máy này."
                }
            }
            Row {
                visible: win.code !== "" && (win.req.type === "confirm" || win.req.type === "display")
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8
                Repeater {
                    model: win.code.split("")
                    delegate: Rectangle {
                        required property var modelData
                        width: 52; height: 64; radius: 14
                        color: Fz.well(0.3); border.width: 1; border.color: Fz.fg(0.14)
                        FText { anchors.centerIn: parent; text: modelData; mono: true; px: 28; weight: Font.Medium }
                    }
                }
            }
            FInput {
                id: input
                visible: !!win.req && (win.req.type === "pin" || win.req.type === "passkey")
                width: parent.width; height: 46
                placeholder: win.req && win.req.type === "passkey" ? "Mã 6 số" : "Mã PIN"
                onAccepted: win.accept()
            }
            Row {
                visible: !!win.req
                width: parent.width
                spacing: 8
                FBtn { width: (parent.width - 8) / 2; height: 46; text: win.req && win.req.type === "display" ? "Hủy" : "Từ chối"; onClicked: win.reject() }
                FBtn {
                    visible: !win.req || win.req.type !== "display"
                    width: (parent.width - 8) / 2; height: 46; kind: "pri"
                    text: !win.req ? "" : win.req.type === "confirm" ? "Mã trùng khớp · Ghép nối" : win.req.type === "authorize" ? "Cho phép" : "Ghép nối"
                    onClicked: win.accept()
                }
            }
            FText {
                visible: !!win.req
                anchors.horizontalCenter: parent.horizontalCenter
                text: "bluez · " + (win.req ? win.req.address : "")
                mono: true; px: 11.5; color: Fz.dim
            }

            // ---- done ----
            Ico {
                visible: !win.req
                anchors.horizontalCenter: parent.horizontalCenter
                width: 72; height: 72; radius: 36; on: true; icon: "p-check"; iconSize: 34
            }
            Column {
                visible: !win.req
                width: parent.width
                spacing: 6
                FText { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: "Đã ghép nối " + win.doneName; px: 20; weight: Font.DemiBold }
                FText { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: "Thiết bị sẽ tự kết nối lần sau."; px: 14; color: Fz.sub2 }
            }
            FBtn {
                visible: !win.req
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Xong"
                onClicked: win.doneName = ""
            }
        }
    }

    Shortcut { sequence: "Escape"; enabled: win.visible; onActivated: win.req ? win.reject() : (win.doneName = "") }
    Shortcut { sequence: "Return"; enabled: win.visible && !!win.req; onActivated: win.accept() }
}
