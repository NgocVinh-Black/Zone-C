import QtQuick
import qs.core.bar
import qs.core.theme
import qs.features.notifications

// Left click opens the notification center, right click toggles do-not-disturb.
IconBlockWidget {
    icon: String.fromCodePoint(0xF0F3)
    iconSize: Tokens.font.size.title
    hoverColour: Colours.yellow
    onClicked: mouse => {
        if (mouse.button === Qt.RightButton)
            NotificationsService.toggleDoNotDisturb();
        else
            NotificationsService.toggleCenter();
    }
}
