import QtQuick
import qs.core.feature

Feature {
    name: "battery"
    barWidget: Qt.resolvedUrl("BatteryWidget.qml")
    popup: ({
            component: Qt.resolvedUrl("BatteryPopup.qml"),
            anchor: "top-right",
            width: 480,
            height: 760
        })
}
