import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core.feature
import qs.core.state
import qs.core.theme
import qs.core.ui
import "PopupLayout.js" as PopupLayout

// One overlay per screen. Morphs a panel from the bar widget into the active
// feature's popup, like Serpantinum v1. Knows nothing about specific popups.
PanelWindow {
    id: host

    readonly property bool isActive: ShellState.activePopup !== "" && ShellState.activeScreen === screen
    readonly property var decl: isActive ? (FeatureLoader.features[ShellState.activePopup]?.popup ?? null) : null
    readonly property var target: decl ? PopupLayout.place(decl.anchor, Scale.s(decl.width), Scale.s(decl.height), width, height, Tokens.popup.marginTop, Tokens.bar.marginSide) : null

    property bool mapped: false
    property bool animate: false
    property int duration: Tokens.anim.morph
    property string loadedPopup: ""

    visible: mapped
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "zone-c-popup"
    WlrLayershell.keyboardFocus: isActive ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onTargetChanged: {
        if (target)
            show();
        else if (mapped)
            hide();
    }

    function originOrTarget(): var {
        const o = ShellState.originRect;
        return o ? o : {
            x: target.x,
            y: target.y,
            width: target.width,
            height: target.height
        };
    }

    function setGeometry(rect: var): void {
        panel.x = rect.x;
        panel.y = rect.y;
        panel.width = rect.width;
        panel.height = rect.height;
    }

    function show(): void {
        closeTimer.stop();
        if (!mapped) {
            animate = false;
            setGeometry(originOrTarget());
            panel.opacity = 0;
            mapped = true;
            duration = Tokens.anim.morph;
        } else {
            duration = Tokens.anim.morphSwitch;
        }
        // Geometry-only changes (screen resize, scale) keep the loaded content.
        if (loadedPopup !== ShellState.activePopup) {
            loadedPopup = ShellState.activePopup;
            content.setSource(decl.component, {
                screen: host.screen
            });
        }
        Qt.callLater(() => {
            animate = true;
            setGeometry(target);
            panel.opacity = 1;
        });
    }

    function hide(): void {
        duration = Tokens.anim.exit;
        const origin = ShellState.originRect;
        if (origin)
            setGeometry(origin);
        panel.opacity = 0;
        closeTimer.restart();
    }

    Timer {
        id: closeTimer

        interval: Tokens.anim.exit
        onTriggered: {
            host.mapped = false;
            host.animate = false;
            host.loadedPopup = "";
            content.source = "";
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: ShellState.close()
    }

    Item {
        anchors.fill: parent
        focus: host.isActive
        Keys.onEscapePressed: ShellState.close()
    }

    Block {
        id: panel

        color: Colours.alpha(Colours.base, Tokens.popup.opacity)
        radius: Tokens.popup.radius
        clip: true

        Behavior on x {
            enabled: host.animate
            Anim { duration: host.duration }
        }
        Behavior on y {
            enabled: host.animate
            Anim { duration: host.duration }
        }
        Behavior on width {
            enabled: host.animate
            Anim { duration: host.duration }
        }
        Behavior on height {
            enabled: host.animate
            Anim { duration: host.duration }
        }
        Behavior on opacity {
            enabled: host.animate
            Anim { duration: host.duration }
        }

        // Swallow clicks so they don't reach the close area behind.
        MouseArea {
            anchors.fill: parent
        }

        Loader {
            id: content

            anchors.fill: parent
            anchors.margins: Tokens.popup.padding

            onStatusChanged: {
                if (status === Loader.Error) {
                    console.warn(`[zone-c popup] "${ShellState.activePopup}" failed to load`);
                    ShellState.close();
                }
            }
        }
    }
}
