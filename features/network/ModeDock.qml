import QtQuick
import QtQuick.Layouts
import qs.core.state
import qs.core.theme
import qs.core.ui

// Bottom of the network popup: Wi-Fi / Bluetooth tabs and the radio power button.
Item {
    id: root

    property string mode: "wifi"
    property color wifiAccent: Colours.blue
    property color btAccent: Colours.mauve
    property bool powered: false
    property bool pending: false

    signal modeSelected(string mode)
    signal powerToggled

    readonly property color accent: mode === "wifi" ? wifiAccent : btAccent

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: Tokens.popup.padding
        width: UiScale.s(360)
        height: UiScale.s(54)
        radius: Tokens.block.radius
        color: Colours.alpha(Colours.white, 0.1)
        border.color: Colours.alpha(Colours.white, 0.1)
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: UiScale.s(6)
            spacing: UiScale.s(6)

            Tab {
                name: "wifi"
                glyph: String.fromCodePoint(0xF1EB)
                label: "Wi-Fi"
                accent: root.wifiAccent
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                Layout.margins: UiScale.s(5)
                color: Colours.alpha(Colours.white, 0.2)
            }

            Tab {
                name: "bt"
                glyph: String.fromCodePoint(0xF294)
                label: "Bluetooth"
                accent: root.btAccent
            }
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: UiScale.s(30)
        width: UiScale.s(48)
        height: width
        radius: width / 2
        color: "transparent"
        border.color: root.pending ? root.accent : (root.powered ? "transparent" : Colours.surface2)
        border.width: UiScale.s(2)
        scale: powerArea.pressed ? 0.9 : (powerArea.containsMouse ? 1.1 : 1)

        Behavior on scale {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutBack
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            opacity: root.powered ? 1 : 0

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.lighter(root.accent, 1.15) }
                GradientStop { position: 1; color: root.accent }
            }

            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }
        }

        Icon {
            id: powerIcon

            anchors.centerIn: parent
            text: root.pending ? String.fromCodePoint(0xF046E) : String.fromCodePoint(0xF011)
            font.pixelSize: Tokens.font.size.iconLarge
            color: root.powered ? Colours.crust : Colours.text

            RotationAnimation on rotation {
                from: 0
                to: 360
                duration: 800
                loops: Animation.Infinite
                running: root.pending
                onRunningChanged: {
                    if (!running)
                        powerIcon.rotation = 0;
                }
            }
        }

        HoverArea {
            id: powerArea

            onClicked: root.powerToggled()
        }
    }

    component Tab: Rectangle {
        id: tab

        property string name: ""
        property string glyph: ""
        property string label: ""
        property color accent: Colours.blue
        readonly property bool selected: root.mode === name

        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: UiScale.s(10)
        color: !selected && tabArea.containsMouse ? Colours.surface1 : "transparent"

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            opacity: tab.selected ? 1 : 0

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.lighter(tab.accent, 1.15) }
                GradientStop { position: 1; color: tab.accent }
            }

            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: UiScale.s(8)

            Icon {
                text: tab.glyph
                font.pixelSize: Tokens.font.size.title
                color: tab.selected ? Colours.crust : Colours.text
            }

            StyledText {
                text: tab.label
                font.pixelSize: Tokens.font.size.pill
                font.weight: Font.Black
                color: tab.selected ? Colours.crust : Colours.text
            }
        }

        HoverArea {
            id: tabArea

            onClicked: root.modeSelected(tab.name)
        }
    }
}
