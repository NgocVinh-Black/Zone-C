import QtQuick
import qs.core.feature

Feature {
    name: "notifications"
    barWidget: Qt.resolvedUrl("NotificationsWidget.qml")
    overlay: Qt.resolvedUrl("NotificationToasts.qml")
    popup: ({
            component: Qt.resolvedUrl("NotificationsPopup.qml"),
            anchor: "top-left",
            width: 520,
            height: 760
        })
}
