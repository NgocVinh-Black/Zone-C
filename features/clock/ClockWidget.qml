import QtQuick
import qs.core.bar
import qs.core.theme
import qs.core.ui
import qs.features.clock

// Time over date. The date types itself in on startup, as in v1.
BarWidget {
    id: root

    property int typedLength: 0

    implicitWidth: column.implicitWidth + Tokens.clock.paddingX * 2
    implicitHeight: column.implicitHeight

    Timer {
        interval: Tokens.clock.typeInterval
        repeat: true
        running: root.typedLength < ClockService.dateText.length
        onTriggered: root.typedLength++
    }

    Column {
        id: column

        anchors.centerIn: parent
        spacing: -2

        StyledText {
            text: ClockService.timeText
            font.pixelSize: Tokens.font.size.clock
            font.weight: Font.Black
            color: Colours.blue
        }

        StyledText {
            text: ClockService.dateText.substring(0, root.typedLength)
            font.pixelSize: Tokens.font.size.small
            color: Colours.subtext0
        }
    }

    HoverArea {
        onClicked: root.openPopup()
    }
}
