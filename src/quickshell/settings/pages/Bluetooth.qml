import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../"
import "../../"
import "../../frost"

// Bluetooth: adapter power and visibility, paired devices (battery, connect / disconnect / forget),
// nearby devices while this page is open (pairing goes through the Zone-C agent).
Column {
    id: page
    property var app
    width: parent ? parent.width : 0

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var devs: adapter && adapter.devices ? (adapter.devices.values || []) : []
    readonly property var paired: devs.filter(d => d.paired || d.bonded)
    readonly property var nearby: devs.filter(d => !d.paired && !d.bonded && d.name && !/^([0-9A-F]{2}[-:]){5}[0-9A-F]{2}$/i.test(d.name))
    Binding { target: page.adapter; property: "discovering"; value: page.adapter !== null && page.adapter.enabled; when: page.adapter !== null }
    function icon(d) {
        let i = (d.icon || "").toLowerCase();
        return /head|ear/.test(i) ? "s-head" : /mouse/.test(i) ? "s-mouse" : /keyboard/.test(i) ? "s-keyboard" : /speaker|audio-card|audio/.test(i) ? "s-spk" : /phone/.test(i) ? "s-cam" : "s-bt";
    }
    function kind(d) {
        let i = (d.icon || "").toLowerCase();
        return /head|ear/.test(i) ? "Tai nghe" : /mouse/.test(i) ? "Chuột" : /keyboard/.test(i) ? "Bàn phím" : /speaker|audio/.test(i) ? "Loa" : /phone/.test(i) ? "Điện thoại" : "Thiết bị";
    }

    Grp {
        width: parent.width
        SRow {
            icon: "s-bt"; iconOn: page.adapter !== null && page.adapter.enabled; title: "Bluetooth"
            sub: page.adapter ? "Hiển thị với tên “" + (page.adapter.name || "zone-c") + "”" : "Không tìm thấy bộ điều hợp"
            FToggle { on: page.adapter !== null && page.adapter.enabled; onToggled: (v) => { if (page.adapter) page.adapter.enabled = v; } }
        }
        SRow {
            title: "Cho phép thiết bị khác tìm thấy"
            FToggle { on: page.adapter !== null && page.adapter.discoverable; onToggled: (v) => { if (page.adapter) page.adapter.discoverable = v; } }
        }
    }

    H3 { text: "Thiết bị của tôi" }
    Grp {
        width: parent.width
        Repeater {
            model: page.paired
            delegate: SRow {
                required property var modelData
                icon: page.icon(modelData); title: modelData.name || modelData.address
                sub: modelData.connected ? (modelData.batteryAvailable ? "Pin " + Math.round(modelData.battery * 100) + "%" : page.kind(modelData)) : "Chưa kết nối"
                FChip { visible: modelData.connected; kind: "ok"; text: "Đã kết nối"; anchors.verticalCenter: parent.verticalCenter }
                FBtn { text: modelData.connected ? "Ngắt" : "Kết nối"; onClicked: { modelData.trusted = true; modelData.connected ? modelData.disconnect() : modelData.connect(); } }
                FIconBtn { ghost: true; icon: "s-trash"; iconSize: 15; label: "Quên thiết bị"; onClicked: modelData.forget() }
            }
        }
        SRow { visible: page.paired.length === 0; title: "Chưa ghép nối thiết bị nào" }
    }

    H3 { text: "Lân cận" + (page.adapter && page.adapter.discovering ? " · đang quét…" : "") }
    Grp {
        width: parent.width
        Repeater {
            model: page.nearby
            delegate: SRow {
                required property var modelData
                icon: page.icon(modelData); title: modelData.name; sub: page.kind(modelData)
                FBtn { kind: "pri"; text: modelData.pairing ? "Đang ghép…" : "Ghép nối"; onClicked: { modelData.trusted = true; modelData.pair(); } }
            }
        }
        SRow { visible: page.nearby.length === 0; title: page.adapter && page.adapter.enabled ? "Đang tìm thiết bị…" : "Bật Bluetooth để tìm thiết bị" }
    }
}
