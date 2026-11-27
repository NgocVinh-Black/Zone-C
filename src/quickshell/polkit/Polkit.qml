import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../"
import "../frost"

// Polkit authentication of the Frost design (Dialogs.dc.html, right dialog). PolkitService runs the agent.
PanelWindow {
    id: win
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "zone-c-polkit"
    WlrLayershell.keyboardFocus: PolkitService.isActive ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    visible: PolkitService.isActive
    color: "transparent"

    readonly property var flow: PolkitService.flow
    property bool busy: false
    property bool wheel: false
    property bool hasFingerprint: false
    readonly property string avatar: ZoneStyle.avatarSource(SystemInfo.avatarPath)   // the default logo follows the preset

    onVisibleChanged: if (visible) { busy = false; pw.text = ""; groups.running = true; focusTimer.restart(); }
    Timer { id: focusTimer; interval: 50; onTriggered: pw.input.forceActiveFocus() }
    Process { id: groups; command: ["bash", "-c", "id -nG; command -v fprintd-list >/dev/null && fprintd-list \"$USER\" 2>/dev/null | grep -q finger && echo FPRINT"]
              stdout: StdioCollector { onStreamFinished: { win.wheel = /\bwheel\b/.test(this.text); win.hasFingerprint = this.text.indexOf("FPRINT") !== -1; } } }
    Connections {
        target: PolkitService
        function onAuthenticationFailed() { win.busy = false; pw.text = ""; shake.restart(); }
    }
    function submit() {
        if (!win.flow || win.busy || pw.text.length === 0) return;
        win.busy = true;
        PolkitService.submit(pw.text);
    }
    Shortcut { sequence: "Escape"; enabled: win.visible; onActivated: PolkitService.cancel() }

    Rectangle { anchors.fill: parent; color: Fz.scrimNight; MouseArea { anchors.fill: parent } }

    Solid {
        id: dialog
        anchors.centerIn: parent
        width: 460
        height: body.implicitHeight + 52
        radius: 28
        SequentialAnimation on anchors.horizontalCenterOffset {
            id: shake; running: false
            NumberAnimation { to: -10; duration: 50 } NumberAnimation { to: 10; duration: 70 } NumberAnimation { to: -6; duration: 60 } NumberAnimation { to: 0; duration: 50 }
        }
        Column {
            id: body
            x: 26; y: 26
            width: parent.width - 52
            spacing: 18

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 64; height: 64; radius: 20; color: Fz.acc
                FIcon { anchors.centerIn: parent; name: "dg-shield"; size: 32; color: Fz.ink }
            }
            Column {
                width: parent.width
                spacing: 6
                FText { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: Fz.tr("Cần xác thực"); px: 20; weight: Font.DemiBold }
                FText {
                    width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap; css: 1.25
                    text: win.flow && win.flow.message ? win.flow.message : Fz.tr("Một ứng dụng cần quyền quản trị.")
                    px: 14; color: Fz.sub2
                }
            }
            Card {
                width: parent.width; height: 54
                Row {
                    x: 14; anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    Item {
                        width: 34; height: 34
                        RoundImage { anchors.fill: parent; radius: 17; source: win.avatar; visible: ready }
                        Rectangle { anchors.fill: parent; radius: 17; color: Fz.acc; visible: win.avatar === ""
                                    FIcon { anchors.centerIn: parent; name: "zc"; size: 20; color: Fz.ink } }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        FText { text: SystemInfo.username; px: 14; weight: Font.Medium }
                        FText { text: win.wheel ? Fz.tr("Quản trị (wheel)") : Fz.tr("Người dùng"); px: 12; color: Fz.sub }
                    }
                }
            }
            FInput {
                id: pw
                width: parent.width; height: 46
                password: !(win.flow && win.flow.responseVisible)
                placeholder: win.flow && win.flow.inputPrompt ? win.flow.inputPrompt.replace(/:\s*$/, "").replace(/^Password$/i, Fz.tr("Mật khẩu")) : Fz.tr("Mật khẩu")
                onAccepted: win.submit()
            }
            FText {
                visible: win.flow && win.flow.supplementaryMessage !== ""
                width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
                text: win.flow ? win.flow.supplementaryMessage : ""
                px: 12.5; color: win.flow && win.flow.supplementaryIsError ? Fz.redTx : Fz.sub2
            }
            Row {
                visible: win.hasFingerprint
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8
                FIcon { name: "dg-finger"; size: 16; color: Fz.sub2; anchors.verticalCenter: parent.verticalCenter }
                FText { text: Fz.tr("Hoặc chạm cảm biến vân tay"); px: 13; color: Fz.sub2 }
            }
            FText { anchors.horizontalCenter: parent.horizontalCenter; text: win.flow ? win.flow.actionId : ""; mono: true; px: 11.5; color: Fz.dim }
            Row {
                width: parent.width
                spacing: 8
                FBtn { width: (parent.width - 8) / 2; height: 44; text: Fz.tr("Hủy"); onClicked: PolkitService.cancel() }
                FBtn { width: (parent.width - 8) / 2; height: 44; kind: "pri"; text: win.busy ? Fz.tr("Đang xác thực…") : Fz.tr("Xác thực"); onClicked: win.submit() }
            }
        }
    }
}
