import QtQuick
import "../../"
import "../../frost"

// "Đồng hồ · Material" from the Widgets artboard: 150px time with the date under it.
Item {
    implicitWidth: 520
    implicitHeight: 210
    Column {
        anchors.verticalCenter: parent.verticalCenter
        FText { text: Qt.formatDateTime(DateTime.now, "HH:mm"); color: Fz.hi; px: 150; weight: Font.ExtraLight; font.letterSpacing: -8 }
        FText { leftPadding: 6; text: Fz.dateLong(DateTime.now); color: Fz.sub2; px: 16 }
    }
}
