import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core.state
import qs.core.theme
import qs.core.ui
import qs.features.osd

// Volume readout near the bottom edge, in the same glass-and-gradient language as
// the popups. It never takes input: the mask stays empty so clicks pass through.
PanelWindow {
    id: root

    visible: OsdService.shown || fade.running
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "zone-c-osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors.bottom: true
    margins.bottom: UiScale.s(OsdService.settings.marginBottom)
    implicitWidth: UiScale.s(330)
    implicitHeight: UiScale.s(96)

    mask: Region {}

    Item {
        id: body

        anchors.fill: parent
        opacity: OsdService.shown ? 1 : 0
        scale: OsdService.shown ? 1 : Tokens.popup.introScale

        transform: Translate {
            y: OsdService.shown ? 0 : UiScale.s(16)

            Behavior on y {
                Anim {}
            }
        }

        Behavior on opacity {
            NumberAnimation {
                id: fade

                duration: Tokens.anim.normal
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            Anim {}
        }

        Rectangle {
            anchors.fill: parent
            radius: Tokens.popup.radius
            color: Colours.alpha(Colours.base, 0.85)
            border.color: Colours.alpha(Colours.white, 0.1)
            border.width: 1
        }

        Icon {
            id: glyph

            anchors.left: parent.left
            anchors.leftMargin: UiScale.s(22)
            anchors.verticalCenter: parent.verticalCenter
            text: OsdService.icon
            font.pixelSize: UiScale.s(28)
            color: OsdService.muted ? Colours.red : Colours.blue

            Behavior on color {
                ColorAnim {}
            }
        }

        StyledText {
            id: readout

            anchors.right: parent.right
            anchors.rightMargin: UiScale.s(22)
            anchors.verticalCenter: parent.verticalCenter
            text: OsdService.muted ? "muted" : OsdService.percent + "%"
            font.pixelSize: Tokens.font.size.title
            font.weight: Font.Black
            color: OsdService.muted ? Colours.subtext1 : Colours.text
        }

        Rectangle {
            id: track

            anchors.left: glyph.right
            anchors.leftMargin: UiScale.s(18)
            anchors.right: readout.left
            anchors.rightMargin: UiScale.s(18)
            anchors.verticalCenter: parent.verticalCenter
            height: UiScale.s(10)
            radius: height / 2
            color: Colours.alpha(Colours.white, 0.05)
            border.color: Colours.alpha(Colours.white, 0.1)
            border.width: 1
            clip: true

            Rectangle {
                height: parent.height
                width: parent.width * OsdService.fill
                radius: parent.radius
                opacity: OsdService.muted ? 0.35 : 1

                gradient: Gradient {
                    orientation: Gradient.Horizontal

                    GradientStop {
                        position: 0
                        color: Colours.blue
                    }

                    GradientStop {
                        position: 1
                        color: Qt.lighter(Colours.blue, Tokens.pill.accentLighter)
                    }
                }

                Behavior on width {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutQuint
                    }
                }

                Behavior on opacity {
                    Anim {}
                }
            }
        }
    }
}
