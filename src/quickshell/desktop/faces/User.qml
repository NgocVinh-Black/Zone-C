import QtQuick
import "../../"
import "../../frost"

// "Người dùng": avatar, user@host and uptime, matching the system panel header.
Glass {
    implicitWidth: 260
    implicitHeight: 110
    radius: 22
    Row {
        x: 18
        anchors.verticalCenter: parent.verticalCenter
        spacing: 14
        Rectangle {
            width: 56; height: 56; radius: 28; color: Fz.acc
            anchors.verticalCenter: parent.verticalCenter
            FIcon { anchors.centerIn: parent; name: "zc"; size: 32; color: Fz.ink }
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            FText { text: SystemInfo.username + "@" + (SystemInfo.hostname || "zone-c"); px: 16; weight: Font.DemiBold }
            FText { text: (SystemInfo.osName || "Arch Linux") + (SystemInfo.uptime ? " · up " + SystemInfo.uptime : ""); color: Fz.sub; px: 12.5 }
        }
    }
}
