pragma Singleton

import QtQuick
import Quickshell

// Which popup is open, on which screen, and with which argument (e.g. a tab).
Singleton {
    id: root

    property string activePopup: ""
    property var activeScreen: null
    // Optional popup argument, such as "wifi" or "bt" for the network popup.
    property string activeArg: ""

    // Toggling the open popup closes it, unless a different argument is given:
    // then the popup stays open and switches to that argument.
    function toggle(name, screen, arg) {
        const target = arg ?? "";
        if (activePopup === name && activeScreen === screen) {
            if (target !== "" && target !== activeArg)
                activeArg = target;
            else
                close();
            return;
        }
        activeScreen = screen;
        activeArg = target;
        activePopup = name;
    }

    function close(): void {
        activePopup = "";
    }
}
