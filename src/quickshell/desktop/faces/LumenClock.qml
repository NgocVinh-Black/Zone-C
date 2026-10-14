import QtQuick
import "../../"
import "../../frost"

// "Material Lumen": heavy digits with a dimmed colon, as on the editor tile.
Item {
    implicitWidth: lumen.implicitWidth
    implicitHeight: lumen.implicitHeight
    Row {
        id: lumen
        FText { text: Qt.formatDateTime(DateTime.now, "HH"); color: Fz.hi; px: 140; weight: Font.DemiBold; font.letterSpacing: -6 }
        FText { text: ":"; color: Fz.hi; opacity: 0.5; px: 140; weight: Font.DemiBold }
        FText { text: Qt.formatDateTime(DateTime.now, "mm"); color: Fz.hi; px: 140; weight: Font.DemiBold; font.letterSpacing: -6 }
    }
}
