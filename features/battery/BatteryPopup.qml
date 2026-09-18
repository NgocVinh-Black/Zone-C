import QtQuick
import QtQuick.Layouts
import qs.core.popup
import qs.core.services
import qs.core.state
import qs.core.theme
import qs.core.ui
import qs.features.battery
import "BatteryLogic.js" as Logic

// Power panel: uptime and log out on top, the battery orb inside radar rings,
// then brightness/volume sliders, hold-to-confirm session actions and power profiles.
PopupBase {
    id: root

    readonly property color batteryColour: Colours[Logic.tone(BatteryService.percent, BatteryService.charging)]
    readonly property color secondaryColour: Colours[Logic.secondaryTone(BatteryService.percent, BatteryService.charging)]
    readonly property color profileColour: Colours[Logic.profileTone(BatteryService.profile)]

    blobPrimary: batteryColour
    blobSecondary: secondaryColour

    Reveal {
        id: introTop
        delay: 100
        overshoot: 1.0
    }
    Reveal {
        id: introCore
        delay: 250
        duration: 900
        overshoot: 1.2
    }
    Reveal {
        id: introSliders
        delay: 350
    }
    Reveal {
        id: introActions
        delay: 450
        easingType: Easing.OutExpo
    }
    Reveal {
        id: introProfiles
        delay: 550
        duration: 850
        overshoot: 0.8
    }

    Repeater {
        model: 3

        Rectangle {
            required property int index

            anchors.centerIn: parent
            anchors.verticalCenterOffset: Scale.s(-70)
            width: Scale.s(320) + index * Scale.s(170)
            height: width
            radius: width / 2
            color: "transparent"
            border.color: root.secondaryColour
            border.width: 1
            opacity: 0.06 - index * 0.02
        }
    }

    // Uptime.
    Row {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: Tokens.popup.padding
        spacing: Scale.s(6)
        opacity: introTop.value

        transform: Translate {
            y: Scale.s(-20) * (1 - introTop.value)
        }

        UptimeBox {
            value: BatteryService.uptimeHours
            unit: "HR"
            tint: root.batteryColour
        }

        StyledText {
            id: colon

            anchors.verticalCenter: parent.verticalCenter
            text: ":"
            font.pixelSize: Tokens.font.size.iconLarge
            font.weight: Font.Black
            color: root.batteryColour

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: 0.2; duration: 800; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 800; easing.type: Easing.InOutSine }
            }
        }

        UptimeBox {
            value: BatteryService.uptimeMinutes
            unit: "MIN"
            tint: root.secondaryColour
        }
    }

    // Log out; widens to show the user name on hover.
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Tokens.popup.padding
        width: logoutArea.containsMouse ? Scale.s(56) + userName.implicitWidth : Scale.s(44)
        height: Scale.s(44)
        radius: Tokens.block.radius
        color: logoutArea.containsMouse ? Colours.alpha(Colours.white, 0.1) : "transparent"
        border.color: logoutArea.containsMouse ? Colours.alpha(Colours.white, 0.2) : "transparent"
        clip: true
        opacity: introTop.value

        Behavior on width {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutQuint
            }
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: Scale.s(13)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Scale.s(12)

            StyledText {
                id: userName

                anchors.verticalCenter: parent.verticalCenter
                text: BatteryService.userName
                opacity: logoutArea.containsMouse ? 1 : 0
            }

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                text: String.fromCodePoint(0xF0343)
                font.pixelSize: Tokens.font.size.title
                color: logoutArea.containsMouse ? Colours.red : Colours.overlay0
            }
        }

        HoverArea {
            id: logoutArea

            onClicked: BatteryService.run("logout")
        }
    }

    BatteryCore {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: Scale.s(-70)
        z: 1
        colourStart: root.batteryColour
        opacity: introCore.value
        scale: 0.9 + 0.1 * introCore.value
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.popup.padding
        spacing: Scale.s(15)
        z: 2

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Scale.s(96)
            radius: Tokens.block.radius
            color: Colours.surface0
            border.color: Colours.surface1
            border.width: 1
            opacity: introSliders.value

            transform: Translate {
                y: Scale.s(20) * (1 - introSliders.value)
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Scale.s(14)
                spacing: Scale.s(12)

                SliderRow {
                    glyph: BatteryService.brightness > 66 ? String.fromCodePoint(0xF00E0) : (BatteryService.brightness > 33 ? String.fromCodePoint(0xF00DF) : String.fromCodePoint(0xF00DE))
                    glyphColour: root.batteryColour
                    value: BatteryService.brightness
                    colour: root.batteryColour
                    onMoved: value => BatteryService.setBrightness(value)
                }

                SliderRow {
                    glyph: Audio.muted || Audio.volume === 0 ? String.fromCodePoint(0xF0581) : (Audio.volume > 0.5 ? String.fromCodePoint(0xF057E) : String.fromCodePoint(0xF0580))
                    glyphColour: Audio.muted ? Colours.overlay0 : root.profileColour
                    value: Math.round(Audio.volume * 100)
                    colour: Audio.muted ? Colours.surface2 : root.profileColour
                    dimmed: Audio.muted
                    onGlyphClicked: Audio.toggleMute(Audio.sink)
                    onMoved: value => Audio.setVolume(Audio.sink, value / 100)
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Scale.s(75)
            spacing: Scale.s(12)

            Repeater {
                model: [
                    { action: "lock", glyph: String.fromCodePoint(0xF023), tone: "mauve", weight: 1 },
                    { action: "suspend", glyph: "ᶻ 𝗓 𝗓", tone: "blue", weight: 1 },
                    { action: "reboot", glyph: String.fromCodePoint(0xF0453), tone: "yellow", weight: 2.5 },
                    { action: "poweroff", glyph: String.fromCodePoint(0xF011), tone: "red", weight: 3.5 }
                ]

                delegate: ActionCapsule {
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    glyph: modelData.glyph
                    accent: Colours[modelData.tone]
                    weight: modelData.weight
                    opacity: introActions.value
                    onConfirmed: BatteryService.run(modelData.action)

                    transform: Translate {
                        y: (Scale.s(30) + index * Scale.s(12)) * (1 - introActions.value)
                    }
                }
            }
        }

        ProfileDock {
            Layout.fillWidth: true
            Layout.preferredHeight: Scale.s(54)
            accent: root.profileColour
            opacity: introProfiles.value

            transform: Translate {
                y: Scale.s(20) * (1 - introProfiles.value)
            }
        }
    }

    component UptimeBox: Rectangle {
        id: box

        property int value: 0
        property string unit: ""
        property color tint: Colours.blue

        width: Scale.s(44)
        height: Scale.s(48)
        radius: Scale.s(10)
        color: Colours.alpha(Colours.white, 0.05)
        border.color: Colours.alpha(Colours.white, 0.1)
        border.width: 1

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: box.tint
            opacity: 0.05
        }

        Column {
            anchors.centerIn: parent

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Logic.twoDigits(box.value)
                font.pixelSize: Tokens.font.size.title
                font.weight: Font.Black
                color: box.tint
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: box.unit
                font.pixelSize: Scale.s(8)
                color: Colours.subtext0
            }
        }
    }

    component SliderRow: RowLayout {
        id: sliderRow

        property string glyph: ""
        property color glyphColour: Colours.text
        property real value: 0
        property color colour: Colours.blue
        property bool dimmed: false

        signal moved(int value)
        signal glyphClicked

        Layout.fillWidth: true
        spacing: Scale.s(15)

        Item {
            Layout.preferredWidth: Scale.s(32)
            Layout.preferredHeight: Scale.s(32)

            Icon {
                anchors.centerIn: parent
                text: sliderRow.glyph
                font.pixelSize: Tokens.font.size.iconLarge
                color: sliderRow.glyphColour
            }

            MouseArea {
                anchors.fill: parent
                onClicked: sliderRow.glyphClicked()
            }
        }

        FillSlider {
            Layout.fillWidth: true
            value: sliderRow.value
            dimmed: sliderRow.dimmed
            colorStart: sliderRow.colour
            trackColor: Colours.surface1
            trackBorder: Colours.surface2
            onMoved: value => sliderRow.moved(value)
        }
    }
}
