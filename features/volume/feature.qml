import QtQuick
import qs.core.feature

Feature {
    name: "volume"
    barWidget: Qt.resolvedUrl("VolumeWidget.qml")
    popup: ({
            component: Qt.resolvedUrl("VolumePopup.qml"),
            anchor: "top-right",
            width: 480,
            height: 760
        })
}
