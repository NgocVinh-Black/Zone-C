import QtQuick
import qs.core.bar
import qs.core.services
import qs.core.theme
import qs.core.ui
import "VolumeLogic.js" as Logic

// Default output volume. Click opens the mixer, scroll changes volume, right click mutes.
BarWidget {
    id: root

    readonly property bool active: !Audio.muted && Audio.volume > 0

    shown: Audio.ready && Audio.sink !== null
    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    Pill {
        id: pill

        icon: Logic.icon(Audio.volume, Audio.muted)
        text: Math.round(Audio.volume * 100) + "%"
        active: root.active
        accent: Colours.peach
        startDelay: root.indexInGroup * Tokens.pill.enterStagger
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                Audio.toggleMute(Audio.sink);
            else
                root.openPopup();
        }
        onScrolled: wheel => Audio.setVolume(Audio.sink, Logic.step(Audio.volume, wheel.angleDelta.y > 0 ? 1 : -1, 0.05))
    }
}
