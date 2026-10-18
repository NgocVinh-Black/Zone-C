import QtQuick

// One shell surface at a time: a panel that shows announces itself, and every other panel that is
// open closes. Put one in each popup / overlay with the panel's own close action.
QtObject {
    id: guard
    required property string name
    required property bool shown
    signal closeRequested()

    onShownChanged: if (shown) Fz.claim(name)
    property Connections watch: Connections {
        target: Fz
        function onSurfaceOpened(n) { if (n !== guard.name && guard.shown) guard.closeRequested(); }
    }
}
