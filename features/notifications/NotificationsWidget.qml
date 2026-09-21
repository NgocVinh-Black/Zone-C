import QtQuick
import qs.core.bar
import qs.core.state
import qs.core.theme
import qs.core.ui
import qs.features.notifications
import "NotificationsLogic.js" as Logic

// Left click opens the notification centre, right click toggles do-not-disturb.
IconBlockWidget {
    id: root

    readonly property int count: NotificationsService.count

    icon: NotificationsService.doNotDisturb ? String.fromCodePoint(0xF009B) : String.fromCodePoint(0xF009A)
    iconSize: Tokens.font.size.title
    hoverColour: NotificationsService.doNotDisturb ? Colours.red : Colours.yellow

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton)
            NotificationsService.toggleDoNotDisturb();
        else
            root.openPopup();
    }

    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: UiScale.s(5)
        visible: root.count > 0 && !NotificationsService.doNotDisturb
        implicitWidth: Math.max(UiScale.s(16), badge.implicitWidth + UiScale.s(8))
        implicitHeight: UiScale.s(16)
        radius: height / 2
        color: Colours.blue

        StyledText {
            id: badge

            anchors.centerIn: parent
            text: Logic.countLabel(root.count)
            font.pixelSize: Tokens.font.size.tiny
            font.weight: Font.Black
            color: Colours.crust
        }
    }
}
