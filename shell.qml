//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1

import QtQuick
import Quickshell
import qs.core.bar
import qs.core.popup

ShellRoot {
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
