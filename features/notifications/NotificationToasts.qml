import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core.state
import qs.core.theme
import qs.core.ui
import qs.features.notifications

// Toast stack under the right end of the bar. The window is only as big as the
// cards, so the rest of the desktop keeps its clicks.
PanelWindow {
    id: root

    visible: NotificationsService.toasts.length > 0
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "zone-c-toast"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors.top: true
    anchors.right: true
    margins.top: Tokens.bar.marginTop + Tokens.bar.height + UiScale.s(10)
    margins.right: Tokens.popup.edgeRight
    implicitWidth: UiScale.s(430)
    implicitHeight: Math.max(1, stack.implicitHeight)

    Column {
        id: stack

        anchors.fill: parent
        spacing: UiScale.s(10)

        Repeater {
            model: NotificationsService.toasts

            delegate: Item {
                id: slot

                required property var modelData

                readonly property bool critical: modelData.urgency >= 2

                width: stack.width
                implicitHeight: card.implicitHeight
                height: implicitHeight
                opacity: 0

                transform: Translate {
                    id: slide

                    x: UiScale.s(40)

                    Behavior on x {
                        Anim {
                            duration: Tokens.anim.medium
                            easing.type: Easing.OutBack
                        }
                    }
                }

                Component.onCompleted: {
                    opacity = 1;
                    slide.x = 0;
                }

                Behavior on opacity {
                    Anim {
                        duration: Tokens.anim.medium
                    }
                }

                NotificationCard {
                    id: card

                    width: parent.width
                    entry: slot.modelData
                    compact: true

                    onDismissed: NotificationsService.dismiss(slot.modelData)
                }

                // Leaves the centre untouched: the card only stops being a toast.
                Timer {
                    running: !(slot.critical && NotificationsService.settings.keepCritical)
                    interval: NotificationsService.settings.timeoutMs
                    onTriggered: NotificationsService.hideToast(slot.modelData.notification.id)
                }
            }
        }
    }
}
