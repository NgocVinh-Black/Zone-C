import QtQuick
import qs.core.feature
import qs.features.clock

Feature {
    name: "clock"
    barWidget: Qt.resolvedUrl("ClockWidget.qml")
    // Taller when the optional schedule strip is configured.
    popup: ({
            component: Qt.resolvedUrl("CalendarPopup.qml"),
            anchor: "top-center",
            width: 1450,
            height: ClockService.hasSchedule ? 750 : 510
        })
}
