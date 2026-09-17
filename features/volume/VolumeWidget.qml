import QtQuick
import qs.core.bar
import qs.core.theme
import qs.core.ui
import qs.features.volume

// Scroll to change volume, right click to mute.
BarWidget {
    id: root

    shown: VolumeService.available
    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    Pill {
        id: pill

        icon: VolumeService.icon
        text: VolumeService.percentText
        active: !VolumeService.muted && VolumeService.volume > 0
        accent: Colours.peach
        startDelay: root.indexInGroup * Tokens.pill.enterStagger
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                VolumeService.toggleMute();
            else
                root.openPopup();
        }
        onScrolled: wheel => VolumeService.stepVolume(wheel.angleDelta.y > 0 ? 1 : -1)
    }
}
