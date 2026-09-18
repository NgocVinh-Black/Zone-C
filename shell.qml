//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core.bar
import qs.core.feature
import qs.core.popup
import qs.core.services
import qs.core.state

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
                    screen: perScreen.modelData
                }
            }
        }
    }
}
