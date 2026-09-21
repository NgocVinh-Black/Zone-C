import QtQuick
import QtQuick.Layouts
import qs.core.popup
import qs.core.state
import qs.core.theme
import qs.core.ui
import qs.features.notifications

// Notification centre: everything still on the shelf, newest first, with critical
// ones held at the top. Do-not-disturb and clear-all live in the header.
PopupBase {
    id: root

    readonly property var entries: NotificationsService.entries
    readonly property color accent: NotificationsService.doNotDisturb ? Colours.subtext0 : Colours.blue

    blobPrimary: accent
    blobSecondary: Colours.mauve
    blobPrimaryOpacity: 0.06
    blobSecondaryOpacity: 0.04

    Reveal {
        id: introHeader
        delay: 80
    }
    Reveal {
        id: introList
        delay: 200
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.popup.padding
        spacing: UiScale.s(16)

        RowLayout {
            Layout.fillWidth: true
            spacing: UiScale.s(12)
            opacity: introHeader.value

            transform: Translate {
                y: UiScale.s(-20) * (1 - introHeader.value)
            }

            StyledText {
                text: "Notifications"
                font.pixelSize: Tokens.font.size.title
                font.weight: Font.Black
            }

            Rectangle {
                visible: root.entries.length > 0
                implicitWidth: total.implicitWidth + UiScale.s(16)
                implicitHeight: UiScale.s(24)
                radius: height / 2
                color: Colours.alpha(root.accent, 0.2)

                StyledText {
                    id: total

                    anchors.centerIn: parent
                    text: root.entries.length
                    font.pixelSize: Tokens.font.size.tiny
                    font.weight: Font.Black
                    color: root.accent
                }
            }

            Item {
                Layout.fillWidth: true
            }

            IconButton {
                icon: NotificationsService.doNotDisturb ? String.fromCodePoint(0xF009B) : String.fromCodePoint(0xF009A)
                iconSize: Tokens.font.size.title
                colour: NotificationsService.doNotDisturb ? Colours.red : Colours.subtext0
                hoverColour: Colours.text

                onClicked: NotificationsService.toggleDoNotDisturb()
            }

            IconButton {
                icon: String.fromCodePoint(0xF05E8)
                iconSize: Tokens.font.size.title
                colour: Colours.subtext0
                hoverColour: Colours.red

                onClicked: NotificationsService.clear()
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            opacity: introList.value

            transform: Translate {
                y: UiScale.s(20) * (1 - introList.value)
            }

            ColumnLayout {
                anchors.centerIn: parent
                visible: root.entries.length === 0
                spacing: UiScale.s(10)

                Icon {
                    Layout.alignment: Qt.AlignHCenter
                    text: String.fromCodePoint(0xF009A)
                    font.pixelSize: UiScale.s(32)
                    color: Colours.surface2
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: NotificationsService.doNotDisturb ? "Do not disturb is on" : "Nothing to catch up on"
                    font.weight: Font.Normal
                    color: Colours.overlay0
                }
            }

            ListView {
                anchors.fill: parent
                clip: true
                spacing: UiScale.s(10)
                model: root.entries
                boundsBehavior: Flickable.StopAtBounds

                delegate: NotificationCard {
                    required property var modelData

                    width: ListView.view.width
                    entry: modelData

                    onDismissed: NotificationsService.dismiss(modelData)
                }
            }
        }
    }
}
