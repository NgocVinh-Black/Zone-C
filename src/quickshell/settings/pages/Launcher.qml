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
        SRow { title: "Vị trí trên màn hình"; CfgSeg { key: "launcher.position"; def: "top"; options: ["Trên", "Giữa", "Dưới"]; values: ["top", "center", "bottom"] } }
        SRow { title: "Chiều rộng"; CfgRange { key: "launcher.width"; from: 400; to: 900; step: 20; def: 680; unit: "px"; sliderWidth: 200 } }
        SRow { title: "Số mục hiển thị"; CfgSelect { key: "launcher.itemCount"; def: 7; options: ["5", "6", "7", "8", "10"]; values: [5, 6, 7, 8, 10] } }
        SRow {
            title: "Lệnh terminal"; sub: "Tiền tố cho lệnh bắt đầu bằng >"
            FInput {
                id: term
                width: 180; height: 36; fontSize: 13.5
                text: Config.getSetting("launcher.terminalCommand", "kitty -e")
                Component.onCompleted: input.font.family = Fz.mono
                onAccepted: Config.setSetting("launcher.terminalCommand", text.trim() || "kitty -e")
                Connections { target: term.input; function onActiveFocusChanged() { if (!term.input.activeFocus) Config.setSetting("launcher.terminalCommand", term.text.trim() || "kitty -e"); } }
            }
        }
        SRow { title: "Sắp xếp thông minh"; sub: "Theo tần suất và thời gian mở"; CfgToggle { key: "launcher.smartRanking"; def: true } }
        SRow { title: "Tự tắt Unikey khi gõ tìm"; CfgToggle { key: "launcher.imGuard"; def: true } }
    }
    Item { width: 1; height: 12 }
    FBtn { kind: "pri"; text: "Mở trình khởi chạy"; onClicked: Fz.open("launcher") }
}
