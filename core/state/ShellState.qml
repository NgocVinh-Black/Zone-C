pragma Singleton

import QtQuick
import Quickshell

// Which popup is open, on which screen, and where it was opened from.
Singleton {
    id: root

    property string activePopup: ""
    property var activeScreen: null
    // Screen-space rectangle of the bar widget that opened the popup: { x, y, width, height }.
    property var originRect: null

    function toggle(name: string, screen: var, rect: var): void {
        if (activePopup === name && activeScreen === screen) {
            close();
            return;
        }
        activeScreen = screen;
        originRect = rect ?? null;
        activePopup = name;
    }

    function close(): void {
        activePopup = "";
    }
}
