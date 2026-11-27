import QtQuick
import "../"
import "../frost"

// Drop-down bound to a settings.json key: labels in `options`, stored values in `values`.
FSelect {
    property string key
    property var values: []
    property var def
    readonly property var stored: Config.getSetting(key, def)
    current: Math.max(0, values.findIndex(v => String(v) === String(stored)))
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    onPicked: (i) => Config.setSetting(key, values[i])
}
