pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core.config
import "schema.js" as Schema

Singleton {
    id: root

    readonly property var settings: Config.feature("clock", Schema.fields)

    readonly property date now: clock.date
    readonly property string timeText: Qt.formatDateTime(now, settings.timeFormat)
    readonly property string dateText: Qt.formatDateTime(now, settings.dateFormat)

    // Optional schedule from `scheduleCommand` (see schema.js).
    readonly property bool hasSchedule: settings.scheduleCommand.length > 0
    property var schedule: ({
            header: "Loading schedule...",
            link: "",
            lessons: []
        })

    SystemClock {
        id: clock

        precision: SystemClock.Seconds
    }

    Process {
        id: scheduleProcess

        command: root.settings.scheduleCommand
        running: root.hasSchedule

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    root.schedule = {
                        header: data.header ?? "",
                        link: data.link ?? "",
                        lessons: Array.isArray(data.lessons) ? data.lessons : []
                    };
                } catch (e) {
                    console.warn("[zone-c clock] schedule command printed invalid JSON:", e);
                }
            }
        }
    }

    Timer {
        running: root.hasSchedule
        repeat: true
        interval: root.settings.scheduleIntervalMinutes * 60 * 1000
        onTriggered: scheduleProcess.running = true
    }
}
