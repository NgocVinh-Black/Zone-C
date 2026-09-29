import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../"

// Hop thoai xac nhan dong cua so (SUPER+Q). Goi qua IPC:
//   zone-c ipc call closeconfirm ask <address> <title> <class>
PanelWindow {
    id: root

    property bool active: false
    property string winAddress: ""
    property string winTitle: ""
    property string winClass: ""
    // 0 = Yes (Dong), 1 = No (Huy)
    property int selected: 0

    readonly property real crLarge: ThemeBackend.borderRadius
    readonly property real crMedium: Math.max(0, ThemeBackend.borderRadius - 2)

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-closeconfirm"
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    anchors { top: true; bottom: true; left: true; right: true }

    visible: active || card.opacity > 0
    color: "transparent"

    function ask(address, title, cls) {
        winAddress = address;
        winTitle = title;
        winClass = cls;
        selected = 0;
        active = true;
        focusTimer.restart();
    }

    function cancel() {
        active = false;
    }

    function confirm() {
        if (winAddress !== "")
            Quickshell.execDetached(["hyprctl", "dispatch",
                'hl.dsp.window.close({ window = "address:' + winAddress + '" })']);
        active = false;
    }

    function choose() {
        if (selected === 0) confirm(); else cancel();
    }

    IpcHandler {
        target: "closeconfirm"

        function ask(address: string, title: string, cls: string): void {
            root.ask(address, title, cls);
        }

        function cancel(): void {
            root.cancel();
        }

        function isOpen(): bool {
            return root.active;
        }
    }

    Timer {
        id: focusTimer
        interval: 30
        onTriggered: keyCatcher.forceActiveFocus()
    }

    // Nen mo
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.55)
        opacity: root.active ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        MouseArea {
            anchors.fill: parent
            enabled: root.active
            onClicked: root.cancel()
        }
    }

    Item {
        id: keyCatcher
        anchors.fill: parent
        focus: root.active

        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Left:
            case Qt.Key_H:
                root.selected = 0; break;
            case Qt.Key_Right:
            case Qt.Key_L:
                root.selected = 1; break;
            case Qt.Key_Tab:
            case Qt.Key_Backtab:
            case Qt.Key_Up:
            case Qt.Key_Down:
                root.selected = 1 - root.selected; break;
            case Qt.Key_Return:
            case Qt.Key_Enter:
            case Qt.Key_Space:
                root.choose(); break;
            case Qt.Key_Y:
                root.confirm(); break;
            case Qt.Key_N:
            case Qt.Key_Escape:
            case Qt.Key_Q:
                root.cancel(); break;
            default:
                return;
            }
            event.accepted = true;
        }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 440
        implicitHeight: layout.implicitHeight + 22 * 2
        color: ThemeBackend.base
        radius: root.crLarge
        border.color: ThemeBackend.surface0
        border.width: 1

        opacity: root.active ? 1 : 0
        scale: root.active ? 1 : 0.94
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.45)
            shadowVerticalOffset: 6
            shadowBlur: 0.6
        }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: layout
            anchors.fill: parent
            anchors.margins: 22
            spacing: 18

            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                Rectangle {
                    Layout.preferredWidth: 46
                    Layout.preferredHeight: 46
                    Layout.alignment: Qt.AlignTop
                    radius: root.crMedium
                    color: Qt.alpha(ThemeBackend.red, 0.14)
                    border.color: Qt.alpha(ThemeBackend.red, 0.35)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "󰅙"
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 24
                        color: ThemeBackend.red
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "Đóng cửa sổ này?"
                        color: ThemeBackend.text
                        font.family: ThemeBackend.fontFamily
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        Layout.fillWidth: true
                    }

                    Text {
                        text: root.winTitle !== "" ? root.winTitle : root.winClass
                        color: ThemeBackend.subtext0
                        font.family: ThemeBackend.fontFamily
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        visible: root.winClass !== ""
                        Layout.topMargin: 4
                        implicitWidth: classText.implicitWidth + 14
                        implicitHeight: classText.implicitHeight + 6
                        radius: height / 2
                        color: ThemeBackend.surface0

                        Text {
                            id: classText
                            anchors.centerIn: parent
                            text: root.winClass
                            color: ThemeBackend.mauve
                            font.family: ThemeBackend.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Medium
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Repeater {
                    model: [
                        { label: "Đóng", icon: "󰅖", key: "Y" },
                        { label: "Huỷ", icon: "󰜺", key: "N" }
                    ]

                    delegate: Rectangle {
                        id: btn
                        required property var modelData
                        required property int index
                        readonly property bool isSel: root.selected === index
                        readonly property color accent: index === 0 ? ThemeBackend.red : ThemeBackend.mauve

                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        radius: root.crMedium
                        color: isSel ? accent : (hover.hovered ? ThemeBackend.surface1 : ThemeBackend.surface0)
                        border.color: isSel ? Qt.lighter(accent, 1.25) : "transparent"
                        border.width: isSel ? 2 : 0
                        scale: isSel ? 1.0 : 0.97
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on scale { NumberAnimation { duration: 120 } }

                        HoverHandler {
                            id: hover
                            onHoveredChanged: if (hovered) root.selected = btn.index
                        }

                        TapHandler { onTapped: { root.selected = btn.index; root.choose(); } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: btn.modelData.icon
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: 15
                                color: btn.isSel ? ThemeBackend.crust : ThemeBackend.text
                            }
                            Text {
                                text: btn.modelData.label
                                font.family: ThemeBackend.fontFamily
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                color: btn.isSel ? ThemeBackend.crust : ThemeBackend.text
                            }
                            Rectangle {
                                implicitWidth: 18
                                implicitHeight: 18
                                radius: 4
                                color: btn.isSel ? Qt.alpha(ThemeBackend.crust, 0.18) : ThemeBackend.surface1
                                Text {
                                    anchors.centerIn: parent
                                    text: btn.modelData.key
                                    font.family: ThemeBackend.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    color: btn.isSel ? ThemeBackend.crust : ThemeBackend.subtext0
                                }
                            }
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: "←  →  chọn   ·   Enter xác nhận   ·   Esc huỷ"
                color: ThemeBackend.overlay1
                font.family: ThemeBackend.fontFamily
                font.pixelSize: 11
            }
        }
    }
}
