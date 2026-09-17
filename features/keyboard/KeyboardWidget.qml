import QtQuick
import qs.core.bar
import qs.core.services
import qs.core.ui
import qs.core.theme
import "KeyboardLogic.js" as Logic

BarWidget {
    id: root

    shown: Hypr.keyboardLayout !== ""
    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    Pill {
        id: pill

        icon: Logic.ICON
        text: Logic.label(Hypr.keyboardLayout)
        startDelay: root.indexInGroup * Tokens.pill.enterStagger
        onClicked: Hypr.switchLayout()
    }
}
