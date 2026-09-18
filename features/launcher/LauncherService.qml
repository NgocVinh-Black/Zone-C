pragma Singleton

import QtQuick
import Quickshell
import qs.core.config
import "schema.js" as Schema

Singleton {
    readonly property var settings: Config.feature("launcher", Schema.fields)

    function open(): void {
        Quickshell.execDetached(settings.command);
    }
}
