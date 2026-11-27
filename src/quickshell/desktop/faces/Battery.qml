import QtQuick
import Quickshell.Services.UPower
import "../../"
import "../../frost"

// "Pin": battery level and time left, in the Frost card style.
Glass {
    id: root
    implicitWidth: 260
    implicitHeight: 90
    radius: 22
    readonly property var dev: UPower.displayDevice
    readonly property int pct: dev.ready ? Math.round(dev.percentage * 100) : 0
    readonly property bool charging: dev.ready && (dev.state === UPowerDeviceState.Charging || dev.state === UPowerDeviceState.PendingCharge)
    readonly property real secs: charging ? dev.timeToFull : dev.timeToEmpty
    readonly property string timeLeft: {
        if (!dev.ready || !dev.isLaptopBattery) return Fz.tr("Máy không dùng pin");
        if (dev.state === UPowerDeviceState.FullyCharged) return Fz.tr("Đã sạc đầy");
        if (secs <= 0) return charging ? Fz.tr("Đang sạc") : Fz.tr("Đang dùng pin");
        let h = Math.floor(secs / 3600), m = Math.round((secs % 3600) / 60);
        return (charging ? Fz.tr("đầy sau ") : Fz.tr("còn ")) + (h > 0 ? h + Fz.tr(" giờ ") : "") + m + Fz.tr(" phút");
    }
    Row {
        x: 20
        anchors.verticalCenter: parent.verticalCenter
        spacing: 14
        FIcon { name: root.charging ? "plug" : "w-bat"; size: 30; color: Fz.acc; anchors.verticalCenter: parent.verticalCenter }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            FText { text: root.pct + "%"; px: 30; weight: Font.Light; css: 1 }
            FText { text: root.timeLeft; color: Fz.sub2; px: 13 }
        }
    }
}
