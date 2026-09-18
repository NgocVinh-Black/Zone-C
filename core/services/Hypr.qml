pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Hyprland state shared by several features. The only place that talks to Hyprland.
Singleton {
    id: root

    readonly property var workspaces: Hyprland.workspaces.values
    // The Quickshell screen of the focused Hyprland monitor, for keyboard-driven popups.
    readonly property var focusedScreen: {
        const name = Hyprland.focusedMonitor?.name ?? "";
        return Quickshell.screens.find(s => s.name === name) ?? Quickshell.screens[0] ?? null;
    }
    readonly property int activeWorkspaceId: Hyprland.focusedWorkspace?.id ?? 1
    property string keyboardLayout: ""

    function isOccupied(id: int): bool {
        const ws = workspaces.find(w => w.id === id);
        if (!ws)
            return false;
        return ws.toplevels ? ws.toplevels.values.length > 0 : (ws.lastIpcObject?.windows ?? 0) > 0;
    }

    function focusWorkspace(id: int): void {
        Hyprland.dispatch(`workspace ${id}`);
    }

    function switchLayout(): void {
        Quickshell.execDetached(["hyprctl", "switchxkblayout", "main", "next"]);
    }

    Connections {
        target: Hyprland

        function onRawEvent(event: HyprlandEvent): void {
            const name = event.name;
            if (name === "activelayout") {
                const data = event.data;
                root.keyboardLayout = data.slice(data.indexOf(",") + 1);
            } else if (["openwindow", "closewindow", "movewindow", "movewindowv2", "createworkspace", "createworkspacev2", "destroyworkspace", "destroyworkspacev2"].includes(name)) {
                Hyprland.refreshWorkspaces();
            }
        }
    }

    Process {
        running: true
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const keyboards = JSON.parse(text).keyboards ?? [];
                    const main = keyboards.find(k => k.main) ?? keyboards[0];
                    if (main)
                        root.keyboardLayout = main.active_keymap;
                } catch (e) {
                    console.warn("[zone-c hypr] could not read keyboard layout:", e);
                }
            }
        }
    }
}
