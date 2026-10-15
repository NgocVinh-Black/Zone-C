import QtQuick
import QtQuick.Effects
import "../../"
import "../../frost"

// Dashboard clock of the Desktop artboard: weekday line, 168px time, greeting.
Item {
    id: root
    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight

    readonly property string greetingWord: {
        let h = DateTime.now.getHours();
        return h < 11 ? Fz.tr("Chào buổi sáng") : h < 14 ? Fz.tr("Chào buổi trưa") : h < 18 ? Fz.tr("Chào buổi chiều") : Fz.tr("Chào buổi tối");
    }
    readonly property string userName: Fz.displayName
    readonly property int eventCount: Agenda.today.length
    property real glyphLift: 30

    Column {
        id: col
        spacing: 4
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Fz.light ? Qt.rgba(1, 1, 1, 0.45) : Qt.rgba(10 / 255, 16 / 255, 20 / 255, 0.35)
            blurMax: 24
            shadowBlur: 1.0
            shadowVerticalOffset: 2
        }
        FText {
            text: Fz.dateLong(DateTime.now).toUpperCase()
            color: Fz.light ? Fz.sub2 : Fz.hi
            px: 15; weight: Font.DemiBold; font.letterSpacing: 15 * 0.16
        }
        // CSS line-height .95 makes a 159.6px line box; Qt draws the glyphs lower, so the text is lifted into it.
        Item {
            width: timeText.implicitWidth
            height: 168 * 0.95
            FText {
                id: timeText
                y: -root.glyphLift
                text: Qt.formatDateTime(DateTime.now, "HH:mm")
                color: Fz.hi
                px: 168; weight: Font.ExtraLight; font.letterSpacing: -8
            }
        }
        FText {
            text: root.greetingWord + (root.userName ? ", " + root.userName : "")
                  + (root.eventCount > 0 ? Fz.tr(" — hôm nay có ") + root.eventCount + Fz.tr(" sự kiện") : Fz.tr(" — hôm nay không có sự kiện"))
            color: Fz.light ? Fz.sub2 : Fz.hi
            px: 18
        }
    }
}
