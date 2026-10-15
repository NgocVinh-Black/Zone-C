import QtQuick
import "../"
import "../../"
import "../../frost"

// Thanh bar: position, style, width, opacity, auto-hide, workspaces, clock, and the module columns
// (click a module to move it out of its column, click an available one to add it on the right).
Column {
    id: page
    property var app
    width: parent ? parent.width : 0

    readonly property var names: ({ left: "Cài đặt", workspaces: "Workspace", media: "Phương tiện", info: "Ghi hình/Hẹn giờ", timedate: "Thời gian", weather: "Thời tiết",
        tray: "Khay", sysmon: "Sysmon", kb: "Bàn phím", wifi: "Mạng", bt: "BT", vol: "Âm lượng", bat: "Pin", focus: "Tiêu điểm", cava: "Visualizer (cava)", actions: "Thao tác" })
    readonly property var all: ["left", "workspaces", "media", "info", "timedate", "weather", "tray", "sysmon", "kb", "wifi", "bt", "vol", "bat", "focus", "cava", "actions"]
    readonly property var mods: Config.getSetting("bar.modules", { left: ["left", "workspaces", "media"], center: ["info", "timedate", "weather"], right: ["tray", "sysmon", "kb", "wifi", "bt", "vol", "bat"] })
    function flat(col) { let out = []; (mods[col] || []).forEach(x => out = out.concat(Array.isArray(x) ? x : [x])); return out; }
    readonly property var used: flat("left").concat(flat("center")).concat(flat("right"))
    function remove(k) {
        let m = JSON.parse(JSON.stringify(mods));
        for (const c of ["left", "center", "right"]) m[c] = (m[c] || []).map(x => Array.isArray(x) ? x.filter(y => y !== k) : x).filter(x => x !== k && !(Array.isArray(x) && x.length === 0));
        Config.setSetting("bar.modules", m);
    }
    function add(k) {
        let m = JSON.parse(JSON.stringify(mods));
        m.right = (m.right || []).concat([k]);
        Config.setSetting("bar.modules", m);
    }

    Grp {
        width: parent.width
        SRow { title: "Vị trí thanh tác vụ"; CfgSeg { key: "bar.position"; def: "top"; options: ["Trên", "Dưới", "Trái", "Phải"]; values: ["top", "bottom", "left", "right"] } }
        SRow { title: "Kiểu thanh tác vụ"; sub: "Mô-đun, đặc hoặc đầy"; CfgSeg { key: "bar.style"; def: "modular"; options: ["Mô-đun", "Đặc", "Đầy"]; values: ["modular", "solid", "fill"] } }
        SRow { title: "Chiều rộng"; CfgRange { key: "bar.width"; from: 50; to: 100; def: 100; unit: "%" } }
        SRow { title: "Độ mờ"; CfgRange { key: "bar.opacity"; from: 0; to: 100; def: 100; unit: "%" } }
        SRow { title: "Tự động ẩn"; sub: "Ẩn khi không di chuột qua"; CfgToggle { key: "bar.autohide" } }
        SRow { title: "Viền riêng cho từng mô-đun"; sub: "Kiểu pill gọn gàng"; CfgToggle { key: "bar.distinctPills"; def: true } }
    }

    H3 { text: "Không gian làm việc & đồng hồ" }
    Grp {
        width: parent.width
        SRow { title: "Số workspace hiển thị"; CfgSelect { key: "bar.workspaceCount"; def: 8; options: ["5", "6", "8", "10"]; values: [5, 6, 8, 10] } }
        SRow { title: "Kiểu workspace"; CfgSeg { key: "bar.workspacesStyle"; def: "pills"; options: ["Số", "Viên", "Pacman"]; values: ["numbers", "pills", "pacman"] } }
        SRow {
            title: "Định dạng thời gian"; sub: "VD: HH:mm:ss hoặc hh:mm AP"
            FInput {
                id: tf
                width: 160; height: 36; fontSize: 13.5
                text: Config.getSetting("bar.time.format", "HH:mm:ss")
                Component.onCompleted: input.font.family = Fz.mono
                onAccepted: Config.setSetting("bar.time.format", text.trim() || "HH:mm:ss")
                Connections { target: tf.input; function onActiveFocusChanged() { if (!tf.input.activeFocus) Config.setSetting("bar.time.format", tf.text.trim() || "HH:mm:ss"); } }
            }
        }
        SRow { title: "Kiểu đồng hồ"; CfgSeg { key: "bar.timeStyle"; def: "classic"; options: ["Cổ điển", "Material", "Ma trận điểm"]; values: ["classic", "material", "badge"] } }
        SRow { title: "Hiển thị ngày"; CfgToggle { key: "bar.showDate"; def: true } }
    }

    H3 { text: "Mô-đun" }
    Row {
        width: parent.width
        spacing: 10
        Repeater {
            model: [["left", "Trái"], ["center", "Giữa"], ["right", "Phải"]]
            delegate: Column {
                required property var modelData
                width: (page.width - 20) / 3
                spacing: 6
                FText { text: modelData[1]; px: 13.5; color: Fz.sub }
                ModuleBox { width: parent.width; keys: page.flat(modelData[0]); on: true; onPicked: (k) => page.remove(k) }
            }
        }
    }
    Item { width: 1; height: 10 }
    Column {
        width: parent.width
        spacing: 6
        FText { text: "Có sẵn · bấm để thêm vào cột phải"; px: 13.5; color: Fz.sub }
        ModuleBox { width: parent.width; keys: page.all.filter(k => page.used.indexOf(k) === -1); on: false; onPicked: (k) => page.add(k) }
    }

    // `.mc`: dashed box of module chips
    component ModuleBox: Item {
        id: mb
        property var keys: []
        property bool on: false
        signal picked(string k)
        implicitHeight: Math.max(40, flow.implicitHeight + 20)
        Canvas {
            anchors.fill: parent
            onPaint: { let c = getContext("2d"); c.reset(); c.setLineDash([4, 3]); c.strokeStyle = Fz.fg(0.18); c.lineWidth = 1;
                       c.beginPath(); c.roundedRect(0.5, 0.5, width - 1, height - 1, 12, 12); c.stroke(); }
            onWidthChanged: requestPaint(); onHeightChanged: requestPaint()
        }
        Flow {
            id: flow
            x: 10; y: 10
            width: parent.width - 20
            spacing: 6
            Repeater {
                model: mb.keys
                delegate: FChip {
                    required property var modelData
                    kind: mb.on ? "acc" : ""
                    text: page.names[modelData] || modelData
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: mb.picked(parent.modelData) }
                }
            }
        }
    }
}
