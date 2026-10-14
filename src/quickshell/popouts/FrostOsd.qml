import QtQuick
import Quickshell
import Quickshell.Wayland
import "../"
import "../frost"

// On-screen display of the Frost design (Notifications.dc.html): volume and brightness as a
// 340px bar 60px from the bottom-left corner; input method, Caps Lock, microphone and airplane
// mode as pills centred 60px from the bottom.
PanelWindow {
    id: win
    screen: OsdController.screen
    WlrLayershell.namespace: "qs-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    anchors { bottom: true; left: true; right: true }
    implicitHeight: 58 + 60 + 40
    color: "transparent"
    visible: OsdController.isVisible || fade.running
    mask: Region { item: pill }

    readonly property string kind: OsdController.kind
    readonly property bool slider: kind === "volume" || kind === "brightness" || (kind === "mic" && !OsdController.sysMicMuted)
    readonly property int value: kind === "volume" ? OsdController.sysVolume : kind === "brightness" ? OsdController.briVal : OsdController.sysMicVolume
    readonly property bool accent: kind === "capslock" && OsdController.stateVal === "on"
    readonly property string icon: {
        if (kind === "volume") return OsdController.sysMuted ? "v-mute" : "t-vol";
        if (kind === "brightness") return "t-sun";
        if (kind === "mic") return OsdController.sysMicMuted ? "t-micoff" : "v-mic";
        if (kind === "capslock" || kind === "numlock") return "t-caps";
        if (kind === "airplane") return "q-plane";
        return "t-kbd";
    }
    readonly property string text: {
        if (kind === "capslock") return OsdController.stateVal === "on" ? "Caps Lock đang bật" : "Caps Lock đã tắt";
        if (kind === "numlock") return OsdController.stateVal === "on" ? "Num Lock đang bật" : "Num Lock đã tắt";
        if (kind === "mic") return "Micro đã tắt";
        if (kind === "airplane") return OsdController.stateVal === "on" ? "Chế độ máy bay đang bật" : "Chế độ máy bay đã tắt";
        if (kind === "ime") return OsdController.stateVal === "unikey" ? "Tiếng Việt · Unikey" : "English · US";
        return "";
    }

    Glass {
        id: pill
        radius: 29
        height: 58
        width: win.slider ? 340 : content.implicitWidth + 40
        x: win.slider ? 60 : (win.width - width) / 2
        y: 40
        color: win.accent ? Fz.acc : Fz.glass
        opacity: OsdController.isVisible ? 1 : 0
        Behavior on opacity { NumberAnimation { id: fade; duration: 160 } }
        HoverHandler { onHoveredChanged: { OsdController.isHovered = hovered; if (hovered) OsdController.cancelHide(); else OsdController.requestHide(); } }

        Row {
            id: content
            x: 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14
            FIcon { name: win.icon; color: win.accent ? Fz.ink : (win.kind === "mic" && !win.slider ? Fz.red : Fz.tx); anchors.verticalCenter: parent.verticalCenter }
            // slider kinds
            Rectangle {
                visible: win.slider
                width: 340 - 40 - 17 - 30 - 28; height: 6; radius: 3
                anchors.verticalCenter: parent.verticalCenter
                color: Fz.fg(0.14)
                clip: true
                Rectangle { width: parent.width * Math.min(1, win.value / 100); height: 6; radius: 3; color: Fz.acc }
            }
            FText { visible: win.slider; width: 30; horizontalAlignment: Text.AlignRight; mono: true; text: win.value; px: 13; anchors.verticalCenter: parent.verticalCenter }
            // message kinds
            FText { visible: !win.slider; text: win.text; px: 14.5; weight: win.accent ? Font.DemiBold : Font.Medium; color: win.accent ? Fz.ink : Fz.tx; anchors.verticalCenter: parent.verticalCenter }
            FChip { visible: win.kind === "ime"; kind: "acc"; text: OsdController.stateVal === "unikey" ? "VI" : "EN"; anchors.verticalCenter: parent.verticalCenter }
        }
    }
}
