pragma Singleton

import QtQuick
import Quickshell
import qs.core.config
import "schema.js" as Schema

Singleton {
    readonly property var settings: Config.feature("clock", Schema.fields)

    readonly property string timeText: Qt.formatDateTime(clock.date, settings.timeFormat)
    readonly property string dateText: Qt.formatDateTime(clock.date, settings.dateFormat)

    SystemClock {
        id: clock

        precision: SystemClock.Seconds
    }
}
