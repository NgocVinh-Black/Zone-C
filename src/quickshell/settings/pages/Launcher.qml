import QtQuick
import "../"
import "../../"
import "../../frost"

// Launcher: position, width, result count, terminal prefix, smart ranking and the Unikey guard.
Column {
    id: page
    property var app
    width: parent ? parent.width : 0

    Grp {
        width: parent.width
        SRow { title: Fz.tr("Vị trí trên màn hình"); CfgSeg { key: "launcher.position"; def: "top"; options: [Fz.tr("Trên"), Fz.tr("Giữa"), Fz.tr("Dưới")]; values: ["top", "center", "bottom"] } }
        SRow { title: Fz.tr("Chiều rộng"); CfgRange { key: "launcher.width"; from: 400; to: 900; step: 20; def: 680; unit: "px"; sliderWidth: 200 } }
        SRow { title: Fz.tr("Số mục hiển thị"); CfgSelect { key: "launcher.itemCount"; def: 7; options: ["5", "6", "7", "8", "10"]; values: [5, 6, 7, 8, 10] } }
        SRow {
            title: Fz.tr("Lệnh terminal"); sub: Fz.tr("Tiền tố cho lệnh bắt đầu bằng >")
            FInput {
                id: term
                width: 180; height: 36; fontSize: 13.5
                text: Config.getSetting("launcher.terminalCommand", "kitty -e")
                Component.onCompleted: input.font.family = Fz.mono
                onAccepted: Config.setSetting("launcher.terminalCommand", text.trim() || "kitty -e")
                Connections { target: term.input; function onActiveFocusChanged() { if (!term.input.activeFocus) Config.setSetting("launcher.terminalCommand", term.text.trim() || "kitty -e"); } }
            }
        }
        SRow { title: Fz.tr("Sắp xếp thông minh"); sub: Fz.tr("Theo tần suất và thời gian mở"); CfgToggle { key: "launcher.smartRanking"; def: true } }
        SRow { title: Fz.tr("Tự tắt Unikey khi gõ tìm"); CfgToggle { key: "launcher.imGuard"; def: true } }
    }
    Item { width: 1; height: 12 }
    FBtn { kind: "pri"; text: Fz.tr("Mở trình khởi chạy"); onClicked: Fz.open("launcher") }
}
