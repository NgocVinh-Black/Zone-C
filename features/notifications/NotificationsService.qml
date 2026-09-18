pragma Singleton

import QtQuick
import Quickshell
import qs.core.config
import "schema.js" as Schema

Singleton {
    readonly property var settings: Config.feature("notifications", Schema.fields)

    function toggleCenter(): void {
        Quickshell.execDetached(settings.toggleCommand);
    }

    function toggleDoNotDisturb(): void {
        Quickshell.execDetached(settings.dndCommand);
    }
}
