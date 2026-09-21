import QtQuick
import Quickshell
import qs.core.state
import qs.core.theme
import qs.core.ui
import qs.features.notifications
import "NotificationsLogic.js" as Logic

// One notification, used both as a toast and as a row in the centre. The urgency
// paints a stripe down the left edge, matching the pill accents on the bar.
Item {
    id: root

    required property var entry
    // Toasts show fewer body lines and no timestamp; the centre shows everything.
    property bool compact: false

    readonly property var notification: entry.notification
    readonly property color accent: Colours[Logic.tone(notification.urgency)]
    readonly property string body: Logic.plain(notification.body)
    readonly property string iconSource: notification.image !== "" ? notification.image : Quickshell.iconPath(notification.appIcon !== "" ? notification.appIcon : notification.desktopEntry, "dialog-information")

    signal dismissed

    implicitHeight: layout.implicitHeight + UiScale.s(28)

    // Two layers: a near-solid base so a toast stays readable with only the
    // wallpaper behind it, and the usual surface tint that lifts on hover.
    Rectangle {
        anchors.fill: parent
        radius: UiScale.s(16)
        color: Colours.alpha(Colours.base, 0.92)
        border.color: Colours.alpha(Colours.white, 0.08)
        border.width: 1
    }

    Rectangle {
        anchors.fill: parent
        radius: UiScale.s(16)
        color: area.containsMouse ? Colours.alpha(Colours.surface1, 0.75) : Colours.alpha(Colours.surface0, 0.55)

        Behavior on color {
            ColorAnim {}
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.leftMargin: UiScale.s(1)
        anchors.verticalCenter: parent.verticalCenter
        width: UiScale.s(3)
        height: parent.height - UiScale.s(22)
        radius: width
        color: root.accent
    }

    HoverArea {
        id: area

        cursorShape: Qt.ArrowCursor
    }

    Item {
        id: layout

        anchors.fill: parent
        anchors.margins: UiScale.s(14)
        anchors.leftMargin: UiScale.s(18)
        implicitHeight: text.implicitHeight + (actions.visible ? actions.height + UiScale.s(10) : 0)

        Image {
            id: badge

            anchors.left: parent.left
            anchors.top: parent.top
            width: UiScale.s(34)
            height: width
            sourceSize.width: width
            sourceSize.height: width
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: status === Image.Ready
            source: root.iconSource
        }

        Icon {
            anchors.centerIn: badge
            visible: !badge.visible
            text: String.fromCodePoint(0xF009A)
            font.pixelSize: Tokens.font.size.iconLarge
            color: root.accent
        }

        Column {
            id: text

            anchors.left: badge.right
            anchors.leftMargin: UiScale.s(14)
            anchors.right: close.left
            anchors.rightMargin: UiScale.s(8)
            anchors.top: parent.top
            spacing: UiScale.s(3)

            Row {
                spacing: UiScale.s(8)

                StyledText {
                    text: Logic.source(root.notification.appName, root.notification.desktopEntry)
                    font.pixelSize: Tokens.font.size.tiny
                    font.weight: Font.Black
                    color: root.accent
                }

                StyledText {
                    visible: !root.compact
                    text: Logic.age(NotificationsService.now, root.entry.time)
                    font.pixelSize: Tokens.font.size.tiny
                    font.weight: Font.Normal
                    color: Colours.subtext1
                }
            }

            StyledText {
                width: parent.width
                text: root.notification.summary
                elide: Text.ElideRight
                font.weight: Font.Black
                color: Colours.text
            }

            StyledText {
                width: parent.width
                visible: text !== ""
                text: root.body
                wrapMode: Text.WordWrap
                elide: Text.ElideRight
                maximumLineCount: root.compact ? 2 : 6
                font.pixelSize: Tokens.font.size.small
                font.weight: Font.Normal
                color: Colours.subtext0
            }
        }

        IconButton {
            id: close

            anchors.right: parent.right
            anchors.top: parent.top
            opacity: area.containsMouse ? 1 : 0.35
            icon: String.fromCodePoint(0xF0156)
            colour: Colours.subtext0
            hoverColour: Colours.red

            onClicked: root.dismissed()

            Behavior on opacity {
                Anim {
                    duration: Tokens.anim.fast
                }
            }
        }

        Row {
            id: actions

            anchors.left: text.left
            anchors.top: text.bottom
            anchors.topMargin: UiScale.s(10)
            spacing: UiScale.s(8)
            visible: root.notification.actions.length > 0
            height: visible ? UiScale.s(30) : 0

            Repeater {
                model: root.notification.actions

                delegate: Rectangle {
                    id: action

                    required property var modelData

                    width: label.implicitWidth + UiScale.s(24)
                    height: parent.height
                    radius: UiScale.s(9)
                    color: actionArea.containsMouse ? Colours.alpha(root.accent, 0.85) : Colours.alpha(Colours.white, 0.07)

                    Behavior on color {
                        ColorAnim {}
                    }

                    StyledText {
                        id: label

                        anchors.centerIn: parent
                        text: action.modelData.text
                        font.pixelSize: Tokens.font.size.small
                        font.weight: Font.Black
                        color: actionArea.containsMouse ? Colours.crust : Colours.text
                    }

                    HoverArea {
                        id: actionArea

                        onClicked: {
                            action.modelData.invoke();
                            root.dismissed();
                        }
                    }
                }
            }
        }
    }
}
