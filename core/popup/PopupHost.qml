import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core.feature
import qs.core.state
import qs.core.theme
import "PopupLayout.js" as PopupLayout
import "../feature/FeatureContract.js" as Contract

// One overlay per screen that shows the active feature's popup, like Serpantinum v1:
// a clipping box grows to the popup's size, and the popup draws its own surface.
// The bar area stays clickable. Knows nothing about specific popups.
PanelWindow {
    id: host

    // The screen this host belongs to, handed in by the shell. Deliberately not the
    // window's own `screen`: that one is written back when the window maps, and
    // mapping is what isActive decides, so reading it here is a binding loop.
    property var targetScreen: null

    readonly property bool isActive: ShellState.activePopup !== "" && ShellState.activeScreen === targetScreen
    readonly property var decl: isActive ? (FeatureLoader.features[ShellState.activePopup]?.popup ?? null) : null
    // The screen size is known before this window is mapped; the window's own size isn't.
    readonly property real areaWidth: targetScreen?.width ?? width
    readonly property real areaHeight: targetScreen?.height ?? height
    readonly property var target: decl ? PopupLayout.place(decl.anchor, UiScale.s(decl.width), UiScale.s(decl.height), areaWidth, areaHeight, Tokens.popup.marginTop, Tokens.popup.edgeLeft, Tokens.popup.edgeRight) : null

    property bool mapped: false
    property bool shown: false
    property bool animate: false
    property int duration: Tokens.anim.morph
    property string loadedPopup: ""
    // Last placed geometry; content keeps this size while the box shrinks away.
    property var lastTarget: null

    screen: targetScreen
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
    // Popups that are typed into ask for the keyboard outright, so a keybind can
    // open one and the first keystroke already lands in its search box.
    WlrLayershell.keyboardFocus: {
        if (!isActive)
            return WlrKeyboardFocus.None;
        return Contract.wantsExclusiveKeyboard(decl) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand;
    }

    // Punch the bar out of the input region so bar widgets keep working while a popup is open.
    mask: Region {
        item: barHole
        intersection: Intersection.Xor
    }

    onTargetChanged: {
        if (target)
            show();
        else if (mapped)
            hide();
    }

    function show(): void {
        closeTimer.stop();
        if (!shown) {
            // Grow from the popup's own corner, as v1 does.
            animate = false;
            box.x = target.x;
            box.y = target.y;
            box.width = 1;
            box.height = 1;
            mapped = true;
            duration = Tokens.anim.morph;
        } else {
            duration = Tokens.anim.morphSwitch;
        }
        shown = true;
        lastTarget = target;

        // Geometry-only changes (screen resize, scale) keep the loaded content.
        if (loadedPopup !== ShellState.activePopup) {
            loadedPopup = ShellState.activePopup;
            content.setSource(decl.component, {
                screen: host.targetScreen
            });
        }

        Qt.callLater(() => {
            if (!host.target)
                return;
            animate = true;
            box.x = host.target.x;
            box.y = host.target.y;
            box.width = host.target.width;
            box.height = host.target.height;
        });
    }

    function hide(): void {
        shown = false;
        duration = Tokens.anim.exit;
        box.width = 1;
        box.height = 1;
        closeTimer.restart();
    }

    Timer {
        id: closeTimer

        interval: Tokens.anim.exit + 40
        onTriggered: {
            host.mapped = false;
            host.animate = false;
            host.loadedPopup = "";
            content.source = "";
        }
    }

    Item {
        id: barHole

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Tokens.bar.marginTop + Tokens.bar.height
    }

    MouseArea {
        anchors.fill: parent
        onClicked: ShellState.close()
    }

    Item {
        id: box

        clip: true
        opacity: host.shown ? 1 : 0

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
            NumberAnimation {
                duration: Tokens.anim.exit
                easing.type: host.shown ? Easing.OutCubic : Easing.InCubic
            }
        }

        // Swallow clicks so they don't reach the close area behind.
        MouseArea {
            anchors.fill: parent
        }

        Loader {
            id: content

            // Laid out at the final size so the popup doesn't reflow while the box grows.
            width: host.lastTarget ? host.lastTarget.width : 0
            height: host.lastTarget ? host.lastTarget.height : 0
            focus: host.isActive

            Keys.onEscapePressed: ShellState.close()

            onLoaded: {
                if (item && "arg" in item)
                    item.arg = Qt.binding(() => ShellState.activeArg);
            }

            onStatusChanged: {
                if (status === Loader.Error) {
                    console.warn(`[zone-c popup] "${ShellState.activePopup}" failed to load`);
                    ShellState.close();
                }
            }
        }
    }

    component Anim: NumberAnimation {
        easing.type: Easing.OutCubic
    }
}
