import QtQuick
import Quickshell
import "../"
import "../../"
import "../../frost"

// Widget: desktop widgets per screen (opens the on-desktop editor), bar hiding while editing, presets.
Column {
    id: page
    property var app
    width: parent ? parent.width : 0
    readonly property var presetNames: ({ dash: "Dashboard", media: "Media station", min: "Minimal" })
    property int pick: 0
    readonly property var current: { let s = Quickshell.screens[0]; return s && Desk.screens[s.name] ? Desk.screens[s.name] : null; }
    readonly property string wallpaper: { let p = Wallpaper.getWallpaperPath(""); return p && !ZoneStyle.isVideo(p) ? "file://" + p : ""; }

    Grp {
        width: parent.width
        Repeater {
            model: Quickshell.screens
            delegate: SRow {
                required property var modelData
                required property int index
                readonly property var st: Desk.screens[modelData.name] || null
                icon: "s-display"
                title: modelData.name + " · " + (modelData.model || (index === 0 ? "màn hình tích hợp" : "màn hình ngoài"))
                sub: st && st.count > 0 ? st.count + " tiện ích · preset " + (page.presetNames[st.preset] || st.preset) : "Chưa có tiện ích"
                FBtn { kind: index === 0 ? "pri" : ""; text: "Mở trình chỉnh sửa"; onClicked: { Desk.editRequested(modelData.name); page.app.open = false; } }
            }
        }
        SRow { title: "Ẩn thanh trong trình chỉnh sửa"; CfgToggle { key: "widgets.hideBarInRedactor"; def: true } }
    }

    H3 { text: "Mẫu tiện ích" }
    Grid {
        width: parent.width
        columns: 3; spacing: 10
        Repeater {
            model: [["dash", "Dashboard", "Đồng hồ, thời tiết, nhạc"], ["media", "Media station", "Nhạc + visualizer"], ["min", "Minimal", "Chỉ đồng hồ"]]
            delegate: Rectangle {
                id: pc
                required property var modelData
                readonly property bool on: page.current ? page.current.preset === modelData[0] : modelData[0] === "dash"
                width: (page.width - 20) / 3; height: 8 + 90 + 8 + 40
                radius: 14
                color: Fz.fg(pcMouse.containsMouse ? 0.06 : 0.03)
                border.width: on ? 2 : 1; border.color: on ? Fz.acc : Fz.fg(0.08)
                Rectangle {
                    id: thumb
                    x: 8; y: 8; width: parent.width - 16; height: 90; radius: 12; clip: true; color: Fz.crust
                    Image { anchors.fill: parent; source: page.wallpaper; fillMode: Image.PreserveAspectCrop; sourceSize.width: 400; opacity: 0.6 }
                }
                Column {
                    x: 8; y: thumb.y + thumb.height + 8
                    FText { text: pc.modelData[1]; px: 12.5; weight: Font.Medium }
                    FText { text: pc.modelData[2]; px: 12.5; color: Fz.sub }
                }
                MouseArea { id: pcMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Desk.presetRequested("", pc.modelData[0]) }
            }
        }
    }
}
