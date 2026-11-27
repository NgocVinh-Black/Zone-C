import QtQuick
import "../"
import "../frost"

// Toggle bound to a settings.json key (dotted path).
FToggle {
    property string key
    property bool def: false
    property bool invert: false
    readonly property bool stored: { let v = Config.getSetting(key, def); return v === true || v === "true"; }
    on: invert ? !stored : stored
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    onToggled: (v) => Config.setSetting(key, invert ? !v : v)
}
