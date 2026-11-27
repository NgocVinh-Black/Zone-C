import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import "./"
import "frost"

// Idle dim of the Frost design (Alerts.dc.html, left): the screen fades under rgba(surf,.72) and the
// focused screen shows a countdown to the lock. Any input ends the dim (Idle resets on activity).
Scope {
    id: dimScope

    property bool active: false
    // `zone-c ipc call dim preview` shows the dim and its dialog for ten seconds
    property bool previewing: false
    readonly property bool shown: active || previewing
    IpcHandler { target: "dim"; function preview(): void { dimScope.previewing = true; dimScope.secsLeft = dimScope.lockIn || 30; previewTimer.restart(); } }
    Timer { id: previewTimer; interval: 10000; onTriggered: dimScope.previewing = false }
    property int lockIn: 0             // seconds from dimming to locking (0 = no lock step)
    property int idleMinutes: 5
    property int secsLeft: 0
    onActiveChanged: if (active) secsLeft = lockIn
    Timer { interval: 1000; repeat: true; running: dimScope.shown && dimScope.secsLeft > 0; onTriggered: dimScope.secsLeft-- }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: dimWindow
            required property var modelData
            readonly property bool focusedScreen: Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name === modelData.name : true

            screen: modelData
            visible: dimRect.opacity > 0
            color: "transparent"
            anchors { top: true; bottom: true; left: true; right: true }
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "zone-c-dim"
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            mask: Region { item: dialog.visible ? dialog : null }

            Rectangle {
                id: dimRect
                anchors.fill: parent
                color: Fz.surf(0.72)
                opacity: dimScope.shown ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
            }

            Glass {
                id: dialog
                visible: dimScope.shown && (dimScope.lockIn > 0 || dimScope.previewing) && dimWindow.focusedScreen
                opacity: dimRect.opacity
                anchors.centerIn: parent
                width: 440; height: dcol.implicitHeight + 56
                radius: 28
                Column {
                    id: dcol
                    x: 28; y: 28
                    width: parent.width - 56
                    spacing: 14
                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 120; height: 120
                        Ring { anchors.fill: parent; size: 120; thickness: 1.8 * 120 / 36; value: dimScope.secsLeft / Math.max(1, dimScope.lockIn || 30) * 100; label: "" }
                        FText { anchors.centerIn: parent; text: dimScope.secsLeft; mono: true; px: 34 }
                    }
                    Column {
                        width: parent.width
                        spacing: 6
                        FText { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: Fz.tr("Màn hình sắp khóa"); px: 20; weight: Font.DemiBold }
                        FText { width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap; px: 14; color: Fz.sub2
                                text: Fz.tr("Không có hoạt động trong ") + dimScope.idleMinutes + Fz.tr(" phút. Di chuột hoặc nhấn phím để tiếp tục.") }
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8
                        FBtn { height: 42; padX: 18; kind: "pri"; text: Fz.tr("Tôi vẫn ở đây"); onClicked: dimScope.previewing = false }
                        FBtn { height: 42; padX: 18; text: Fz.tr("Khóa ngay"); onClicked: Quickshell.execDetached(["bash", Caching.zoneCDir + "/scripts/lock.sh"]) }
                    }
                }
            }
        }
    }
}
