import QtQuick
import qs.core.bar
import qs.core.theme
import qs.core.ui
import qs.features.media

// Album art, title/artist and previous / play-pause / next controls.
BarWidget {
    id: root

    readonly property string playIcon: String.fromCodePoint(0xF040A)
    readonly property string pauseIcon: String.fromCodePoint(0xF03E4)
    readonly property string previousIcon: String.fromCodePoint(0xF04AE)
    readonly property string nextIcon: String.fromCodePoint(0xF04AD)

    shown: MediaService.available
    implicitWidth: content.implicitWidth + Tokens.media.padding * 2 - Tokens.block.paddingX * 2
    implicitHeight: content.implicitHeight

    Row {
        id: content

        anchors.centerIn: parent
        spacing: root.compact ? Tokens.media.spacingCompact : Tokens.media.spacing

        Item {
            id: info

            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: infoRow.implicitWidth
            implicitHeight: infoRow.implicitHeight
            scale: infoArea.containsMouse ? 1.02 : 1

            Behavior on scale {
                Anim {
                    easing.type: Easing.OutExpo
                }
            }

            Row {
                id: infoRow

                spacing: Tokens.media.infoSpacing

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Tokens.media.art
                    height: Tokens.media.art
                    radius: Tokens.media.artRadius
                    color: Colours.surface1
                    border.width: MediaService.playing ? 1 : 0
                    border.color: Colours.mauve
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: MediaService.artUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: Colours.alpha(Colours.mauve, Tokens.media.artTintAlpha)
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.compact ? Tokens.media.titleWidthCompact : Tokens.media.titleWidth

                    StyledText {
                        width: parent.width
                        text: MediaService.title
                        elide: Text.ElideRight
                        font.pixelSize: Tokens.font.size.pill
                        font.weight: Font.Black
                    }

                    StyledText {
                        width: parent.width
                        visible: text !== ""
                        text: MediaService.artist
                        elide: Text.ElideRight
                        font.pixelSize: Tokens.font.size.tiny
                        font.weight: Font.Black
                        color: Colours.subtext0
                    }
                }
            }

            HoverArea {
                id: infoArea

                onClicked: root.openPopup()
            }
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.compact ? Tokens.media.spacingCompact / 2 : Tokens.media.spacingCompact

            IconButton {
                anchors.verticalCenter: parent.verticalCenter
                icon: root.previousIcon
                iconSize: Tokens.media.controlIcon
                onClicked: MediaService.previous()
            }

            IconButton {
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: Tokens.media.controlMain
                implicitHeight: Tokens.media.controlMain
                icon: MediaService.playing ? root.pauseIcon : root.playIcon
                iconSize: Tokens.media.controlIconMain
                colour: Colours.text
                hoverColour: Colours.green
                hoverScale: 1.15
                onClicked: MediaService.playPause()
            }

            IconButton {
                anchors.verticalCenter: parent.verticalCenter
                icon: root.nextIcon
                iconSize: Tokens.media.controlIcon
                onClicked: MediaService.next()
            }
        }
    }
}
