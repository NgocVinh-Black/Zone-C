import QtQuick
import qs.core.feature

Feature {
    name: "media"
    barWidget: Qt.resolvedUrl("MediaWidget.qml")
    popup: ({
            component: Qt.resolvedUrl("MusicPopup.qml"),
            anchor: "top-left",
            width: 700,
            height: 620
        })
}
