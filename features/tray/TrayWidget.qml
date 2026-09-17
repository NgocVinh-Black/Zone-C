import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.core.bar
import qs.core.theme
import qs.core.ui

// System tray icons. Left click activates, middle click secondary action, right click menu.
BarWidget {
    id: root

    shown: repeater.count > 0
    implicitWidth: row.implicitWidth + Tokens.tray.paddingX * 2
    implicitHeight: Tokens.tray.icon

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Tokens.tray.spacing

        Repeater {
            id: repeater

            model: SystemTray.items

            delegate: Item {
                id: entry

                required property SystemTrayItem modelData
                required property int index

                width: Tokens.tray.icon
                height: Tokens.tray.icon
                opacity: 0
                scale: 0

                Component.onCompleted: appear.start()

                SequentialAnimation {
                    id: appear

                    PauseAnimation {
                        duration: entry.index * Tokens.pill.enterStagger
                    }
                    ParallelAnimation {
                        Anim {
                            target: entry
                            property: "opacity"
                            to: Tokens.tray.idleOpacity
                        }
                        Anim {
                            target: entry
                            property: "scale"
                            to: 1
                            easing.type: Easing.OutBack
                        }
                    }
                }

                IconImage {
                    anchors.fill: parent
                    source: entry.modelData.icon
                    implicitSize: Tokens.tray.icon
                    scale: area.containsMouse ? Tokens.tray.hoverScale : 1

                    Behavior on scale {
                        Anim {}
                    }
                }

                QsMenuAnchor {
                    id: menu

                    anchor.window: root.barWindow
                    anchor.item: entry
                    menu: entry.modelData.menu
                }

                HoverArea {
                    id: area

                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onContainsMouseChanged: {
                        if (!appear.running)
                            entry.opacity = containsMouse ? 1 : Tokens.tray.idleOpacity;
                    }
                    onClicked: mouse => {
                        const item = entry.modelData;
                        if (mouse.button === Qt.MiddleButton)
                            item.secondaryActivate();
                        else if (mouse.button === Qt.RightButton || item.onlyMenu)
                            item.hasMenu ? menu.open() : item.activate();
                        else
                            item.activate();
                    }
                }
            }
        }
    }
}
