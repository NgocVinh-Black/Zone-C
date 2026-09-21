import QtQuick
import qs.core.feature

Feature {
    name: "launcher"
    barWidget: Qt.resolvedUrl("LauncherWidget.qml")
    popup: ({
            component: Qt.resolvedUrl("LauncherPopup.qml"),
            anchor: "center",
            width: 800,
            height: 700,
            keyboard: "exclusive"
        })
}
