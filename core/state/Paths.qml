pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property string home: Quickshell.env("HOME")
    readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || home + "/.cache") + "/zone-c"
}
