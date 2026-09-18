import QtQuick
import qs.core.feature

Feature {
    name: "network"
    barWidget: Qt.resolvedUrl("NetworkWidget.qml")
    // Also opened by the bluetooth widget with the "bt" argument.
    popup: ({
            component: Qt.resolvedUrl("NetworkPopup.qml"),
            anchor: "top-right",
            width: 900,
            height: 700
        })
}
