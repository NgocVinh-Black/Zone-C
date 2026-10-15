import QtQuick
import "../"
import "../frost"

// Segmented control bound to a settings.json key: labels + the values stored for them.
FSeg {
    property string key
    property var values: []
    property var def
    readonly property var stored: Config.getSetting(key, def)
    current: Math.max(0, values.findIndex(v => String(v) === String(stored)))
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    onPicked: (i) => Config.setSetting(key, values[i])
}
