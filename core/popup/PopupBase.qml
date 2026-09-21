import QtQuick
import qs.core.state
import qs.core.theme

// Root type for a feature popup: the rounded v1 surface with two slowly orbiting
// colour blobs, and the shared "lift and fade in" entrance. Content goes inside.
Item {
    id: root

    // Set by PopupHost.
    property var screen: null
    // Optional argument from ShellState (e.g. a tab name).
    property string arg: ""

    // Blob colours and strength; popups tint them by state.
    property color blobPrimary: Colours.mauve
    property color blobSecondary: Colours.blue
    property real blobPrimaryOpacity: 0.08
    property real blobSecondaryOpacity: 0.06

    // 0 → 1 over the entrance; popups can stagger their own sections from it.
    property real intro: 0
    // Angle for slow background motion, one turn per Tokens.anim.orbit.
    property real orbitAngle: 0

    default property alias content: body.data
    readonly property alias surface: surface

    NumberAnimation on intro {
        from: 0
        to: 1
        duration: 800
        easing.type: Easing.OutQuart
    }

    NumberAnimation on orbitAngle {
        from: 0
        to: Math.PI * 2
        duration: Tokens.anim.orbit
        loops: Animation.Infinite
    }

    Item {
        anchors.fill: parent
        scale: Tokens.popup.introScale + (1 - Tokens.popup.introScale) * root.intro
        opacity: root.intro

        transform: Translate {
            y: Tokens.popup.introLift * (1 - root.intro)
        }

        Rectangle {
            id: surface

            anchors.fill: parent
            radius: Tokens.popup.radius
            color: Colours.base
            border.color: Colours.surface0
            border.width: 1
            clip: true

            Rectangle {
                width: parent.width * 0.8
                height: width
                radius: width / 2
                x: (parent.width - width) / 2 + Math.cos(root.orbitAngle * 2) * UiScale.s(150)
                y: (parent.height - height) / 2 + Math.sin(root.orbitAngle * 2) * UiScale.s(100)
                color: root.blobPrimary
                opacity: root.blobPrimaryOpacity

                Behavior on color {
                    ColorAnimation { duration: 1000 }
                }
                Behavior on opacity {
                    NumberAnimation { duration: 1000 }
                }
            }

            Rectangle {
                width: parent.width * 0.9
                height: width
                radius: width / 2
                x: (parent.width - width) / 2 - Math.sin(root.orbitAngle * 1.5) * UiScale.s(150)
                y: (parent.height - height) / 2 - Math.cos(root.orbitAngle * 1.5) * UiScale.s(100)
                color: root.blobSecondary
                opacity: root.blobSecondaryOpacity

                Behavior on color {
                    ColorAnimation { duration: 1000 }
                }
                Behavior on opacity {
                    NumberAnimation { duration: 1000 }
                }
            }

            Item {
                id: body

                anchors.fill: parent
            }
        }
    }
}
