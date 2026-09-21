//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core.bar
import qs.core.feature
import qs.core.overlay
import qs.core.popup
import qs.core.services
import qs.core.state
// Quickshell only registers a qs.<dir> module for directories reached through the
// static import graph. Every feature file is loaded by URL (FeatureLoader, Bar,
// PopupHost, OverlayHost), so without these imports none of them can resolve
// their own module.
import qs.features.battery
import qs.features.bluetooth
import qs.features.clipboard
import qs.features.clock
import qs.features.keyboard
import qs.features.launcher
import qs.features.media
import qs.features.network
import qs.features.notifications
import qs.features.osd
import qs.features.tray
import qs.features.volume
import qs.features.weather
import qs.features.workspaces

ShellRoot {
    // Lets Hyprland keybinds drive the shell:
    //   qs -c zone-c ipc call popup toggle battery
    IpcHandler {
        target: "popup"

        function toggle(name: string, arg: string): void {
            if (!FeatureLoader.features[name]?.popup) {
                console.warn(`[zone-c ipc] no popup named "${name}"`);
                return;
            }
            ShellState.toggle(name, Hypr.focusedScreen, arg ?? "");
        }

        function close(): void {
            ShellState.close();
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            Scope {
                id: perScreen

                required property ShellScreen modelData

                Bar {
                    screen: perScreen.modelData
                }

                PopupHost {
                    targetScreen: perScreen.modelData
                }

                OverlayHost {
                    screen: perScreen.modelData
                }
            }
        }
    }
}
