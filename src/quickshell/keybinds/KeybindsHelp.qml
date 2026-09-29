import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../"

// Bang phim tat (SUPER+/). Goi qua IPC: zone-c ipc call keybinds toggle
PanelWindow {
    id: root

    property bool active: false
    property string query: ""

    readonly property real crLarge: ThemeBackend.borderRadius
    readonly property real crMedium: Math.max(0, ThemeBackend.borderRadius - 2)
    readonly property real crSmall: Math.max(0, ThemeBackend.borderRadius - 4)

    // col: cot hien thi (0..2). k: cac phim, "|" = cach khac, "+" = bam cung luc.
    readonly property var sections: [
        { col: 0, icon: "󰀻", title: "Mở ứng dụng", accent: "blue", rows: [
            { k: "Super (nhấn rồi thả)|Super+D", d: "Launcher tìm ứng dụng" },
            { k: "Super+T|Super+Enter", d: "Terminal (foot)" },
            { k: "Super+W|Super+G", d: "Chrome" },
            { k: "Super+C", d: "VS Code" },
            { k: "Super+E", d: "Trình quản lý file" },
            { k: "Ctrl+Alt+V", d: "Chỉnh âm thanh" },
            { k: "Super+/", d: "Bảng phím tắt này" } ] },
        { col: 0, icon: "󰕮", title: "Bảng của Zone-C", accent: "mauve", rows: [
            { k: "Super+V", d: "Lịch sử clipboard" },
            { k: "Super+M|Super+B", d: "Nhạc / bảng hệ thống" },
            { k: "Super+S|Super+N", d: "Lịch / mạng" },
            { k: "Super+Shift+V", d: "Âm lượng" },
            { k: "Super+Shift+W", d: "Chọn hình nền" },
            { k: "Super+H", d: "Cài đặt / hướng dẫn" },
            { k: "Super+A|Super+R", d: "Tự ẩn bar / tải lại shell" } ] },
        { col: 2, icon: "󰄀", title: "Chụp & quay màn hình", accent: "peach", rows: [
            { k: "Print|Shift+Print", d: "Chụp / chụp rồi sửa" },
            { k: "Super+Print|Super+Shift+Print", d: "Toàn màn hình / rồi sửa" },
            { k: "Super+Shift+S", d: "Flameshot" },
            { k: "Super+Shift+Alt+S", d: "Chụp vùng (zone-c)" },
            { k: "Super+Alt+R", d: "Quay màn hình" } ] },
        { col: 1, icon: "󰖲", title: "Cửa sổ", accent: "sapphire", rows: [
            { k: "Super+Q", d: "Đóng (hỏi Yes/No)" },
            { k: "Super+Shift+Q", d: "Đóng ngay, không hỏi" },
            { k: "Super+F|Super+Alt+F", d: "Toàn màn hình / phóng to" },
            { k: "Super+Shift+F|Super+Alt+Space", d: "Cửa sổ nổi" },
            { k: "Super+P", d: "Ghim ở mọi workspace" },
            { k: "Super+Alt+\\", d: "Chế độ PiP" },
            { k: "Ctrl+Super+\\", d: "Đưa ra giữa" },
            { k: "Ctrl+Super+Alt+\\", d: "Cỡ 55×70% và ra giữa" },
            { k: "Super+←↑↓→", d: "Chuyển sang cửa sổ bên cạnh" },
            { k: "Super+Shift+←↑↓→", d: "Di chuyển cửa sổ" },
            { k: "Super+Alt+←↑↓→", d: "Đổi kích thước" },
            { k: "Super+=|Super+-", d: "Rộng ra / hẹp lại" },
            { k: "Super+Shift+=|Super+Shift+-", d: "Cao lên / thấp xuống" },
            { k: "Super+Chuột trái|Super+Z", d: "Kéo cửa sổ" },
            { k: "Super+Chuột phải|Super+X", d: "Kéo đổi kích thước" } ] },
        { col: 1, icon: "󰓩", title: "Nhóm cửa sổ (tab)", accent: "teal", rows: [
            { k: "Alt+Tab|Shift+Alt+Tab", d: "Chuyển cửa sổ" },
            { k: "Super+,", d: "Gộp / bỏ nhóm" },
            { k: "Super+U", d: "Tách khỏi nhóm" },
            { k: "Super+Shift+,", d: "Khoá nhóm" },
            { k: "Ctrl+Alt+Tab|Ctrl+Shift+Alt+Tab", d: "Tab kế tiếp / trước" } ] },
        { col: 2, icon: "󰍺", title: "Workspace", accent: "green", rows: [
            { k: "Super+1…0", d: "Sang workspace 1–10" },
            { k: "Super+Shift+1…0|Super+Alt+1…0", d: "Chuyển cửa sổ sang đó" },
            { k: "Ctrl+Super+1…0", d: "Sang nhóm workspace" },
            { k: "Ctrl+Super+Alt+1…0", d: "Chuyển cửa sổ sang nhóm" },
            { k: "Ctrl+Super+←→|Super+PgUp/PgDn", d: "Workspace trước / sau" },
            { k: "Super+Cuộn", d: "Workspace trước / sau" },
            { k: "Ctrl+Super+Cuộn", d: "Nhảy 10 workspace" },
            { k: "Vuốt ngang 3 ngón", d: "Đổi workspace (touchpad)" },
            { k: "Ctrl+Super+Shift+←→", d: "Mang cửa sổ sang trước / sau" },
            { k: "Super+Alt+PgUp/PgDn|Super+Alt+Cuộn", d: "Mang cửa sổ sang trước / sau" },
            { k: "Super+Alt+S|Ctrl+Super+Shift+↑", d: "Cất vào workspace ẩn" },
            { k: "Ctrl+Super+Shift+↓", d: "Lấy ra từ workspace ẩn" } ] },
        { col: 0, icon: "󰝚", title: "Hệ thống & media", accent: "pink", rows: [
            { k: "Super+L|Nút nguồn", d: "Khoá màn hình" },
            { k: "Super+Shift+L", d: "Ngủ" },
            { k: "Super+Space|Ctrl+Super+Space", d: "Phát / dừng nhạc" },
            { k: "Ctrl+Super+=|Ctrl+Super+-", d: "Bài tiếp / bài trước" },
            { k: "Super+Shift+M|Mute", d: "Tắt tiếng loa" },
            { k: "Phím âm lượng|Phím độ sáng", d: "Âm lượng / độ sáng" },
            { k: "Phím Mic", d: "Tắt / bật micro" } ] }
    ]

    function norm(t) {
        return String(t).toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "").replace(/đ/g, "d");
    }
    function rowMatches(row) {
        if (query.trim() === "") return true;
        const q = norm(query.trim());
        return norm(row.d).indexOf(q) !== -1 || norm(row.k).indexOf(q) !== -1;
    }
    function splitKey(alt) {
        // "Super+=" / "Super+-" / "Super+Shift+," giu nguyen phim cuoi
        const parts = alt.split("+");
        const out = [];
        for (let i = 0; i < parts.length; i++) {
            if (parts[i] === "" && i + 1 < parts.length) { out.push("+"); i++; continue; }
            if (parts[i] !== "") out.push(parts[i]);
        }
        return out;
    }

    function open() { query = ""; searchInput.text = ""; active = true; focusTimer.restart(); }
    function close() { active = false; }
    function toggle() { if (active) close(); else open(); }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-keybinds"
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    visible: active || card.opacity > 0
    color: "transparent"

    IpcHandler {
        target: "keybinds"
        function toggle(): void { root.toggle(); }
        function open(): void { root.open(); }
        function close(): void { root.close(); }
        function isOpen(): bool { return root.active; }
    }

    Timer { id: focusTimer; interval: 30; onTriggered: searchInput.forceActiveFocus() }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.55)
        opacity: root.active ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        MouseArea { anchors.fill: parent; enabled: root.active; onClicked: root.close() }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(1320, root.width - 48)
        height: Math.min(content.implicitHeight + 20 * 2, root.height - 32)
        color: ThemeBackend.base
        radius: root.crLarge
        border.color: ThemeBackend.surface0
        border.width: 1
        clip: true

        opacity: root.active ? 1 : 0
        scale: root.active ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.45)
            shadowVerticalOffset: 6
            shadowBlur: 0.6
        }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: 20
            spacing: 12

            // Tieu de + o tim kiem
            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                Rectangle {
                    Layout.preferredWidth: 44
                    Layout.preferredHeight: 44
                    radius: root.crMedium
                    color: Qt.alpha(ThemeBackend.mauve, 0.14)
                    border.color: Qt.alpha(ThemeBackend.mauve, 0.35)
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "󰌌"
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 22
                        color: ThemeBackend.mauve
                    }
                }

                ColumnLayout {
                    spacing: 2
                    Text {
                        text: "Phím tắt"
                        color: ThemeBackend.text
                        font.family: ThemeBackend.fontFamily
                        font.pixelSize: 18
                        font.weight: Font.Bold
                    }
                    Text {
                        text: "Super = phím Windows"
                        color: ThemeBackend.subtext0
                        font.family: ThemeBackend.fontFamily
                        font.pixelSize: 12
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredWidth: 320
                    Layout.preferredHeight: 38
                    radius: root.crMedium
                    color: ThemeBackend.surface0
                    border.color: searchInput.activeFocus ? Qt.alpha(ThemeBackend.mauve, 0.6) : "transparent"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        Text {
                            text: "󰍉"
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 15
                            color: ThemeBackend.subtext0
                        }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            color: ThemeBackend.text
                            font.family: ThemeBackend.fontFamily
                            font.pixelSize: 13
                            selectionColor: Qt.alpha(ThemeBackend.mauve, 0.4)
                            clip: true
                            onTextChanged: root.query = text

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                visible: searchInput.text === ""
                                text: "Tìm phím tắt…"
                                color: ThemeBackend.overlay1
                                font: searchInput.font
                            }

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Escape) {
                                    if (searchInput.text !== "") searchInput.text = "";
                                    else root.close();
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Slash && (event.modifiers & Qt.MetaModifier)) {
                                    root.close();
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Down || event.key === Qt.Key_PageDown) {
                                    flick.contentY = Math.min(flick.contentY + (event.key === Qt.Key_Down ? 60 : flick.height * 0.8),
                                                              Math.max(0, flick.contentHeight - flick.height));
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Up || event.key === Qt.Key_PageUp) {
                                    flick.contentY = Math.max(0, flick.contentY - (event.key === Qt.Key_Up ? 60 : flick.height * 0.8));
                                    event.accepted = true;
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 38
                    Layout.preferredHeight: 38
                    radius: root.crMedium
                    color: closeHover.hovered ? ThemeBackend.surface1 : ThemeBackend.surface0
                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 15
                        color: ThemeBackend.text
                    }
                    HoverHandler { id: closeHover }
                    TapHandler { onTapped: root.close() }
                }
            }

            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: ThemeBackend.surface0 }

            Flickable {
                id: flick
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitHeight: columns.implicitHeight
                contentHeight: columns.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                RowLayout {
                    id: columns
                    width: flick.width
                    spacing: 14

                    Repeater {
                        model: 3
                        delegate: ColumnLayout {
                            id: colItem
                            required property int index
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.alignment: Qt.AlignTop
                            spacing: 10

                            Repeater {
                                model: root.sections.filter(sec => sec.col === colItem.index)
                                delegate: Rectangle {
                                    id: secCard
                                    required property var modelData
                                    readonly property var shown: modelData.rows.filter(r => root.rowMatches(r))
                                    readonly property color accent: ThemeBackend[modelData.accent] || ThemeBackend.mauve

                                    visible: shown.length > 0
                                    Layout.fillWidth: true
                                    implicitHeight: secLayout.implicitHeight + 12 * 2
                                    radius: root.crMedium
                                    color: ThemeBackend.mantle
                                    border.color: ThemeBackend.surface0
                                    border.width: 1

                                    ColumnLayout {
                                        id: secLayout
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 5

                                        RowLayout {
                                            spacing: 8
                                            Text {
                                                text: secCard.modelData.icon
                                                font.family: "Iosevka Nerd Font"
                                                font.pixelSize: 15
                                                color: secCard.accent
                                            }
                                            Text {
                                                text: secCard.modelData.title.toUpperCase()
                                                color: secCard.accent
                                                font.family: ThemeBackend.fontFamily
                                                font.pixelSize: 12
                                                font.weight: Font.Bold
                                                font.letterSpacing: 0.8
                                            }
                                        }

                                        Repeater {
                                            model: secCard.shown
                                            delegate: RowLayout {
                                                id: rowItem
                                                required property var modelData
                                                Layout.fillWidth: true
                                                spacing: 10

                                                Text {
                                                    Layout.fillWidth: true
                                                    Layout.alignment: Qt.AlignVCenter
                                                    text: rowItem.modelData.d
                                                    color: ThemeBackend.subtext1
                                                    font.family: ThemeBackend.fontFamily
                                                    font.pixelSize: 12
                                                    wrapMode: Text.Wrap
                                                }

                                                Flow {
                                                    id: keyFlow
                                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                                    Layout.maximumWidth: secCard.width * 0.58
                                                    Layout.preferredWidth: Math.min(implicitW, secCard.width * 0.58)
                                                                                                        spacing: 4
                                                    property real implicitW: 0

                                                    Repeater {
                                                        model: rowItem.modelData.k.split("|")
                                                        delegate: Row {
                                                            id: altRow
                                                            required property string modelData
                                                            required property int index
                                                            spacing: 3
                                                            layoutDirection: Qt.LeftToRight
                                                            Component.onCompleted: keyFlow.implicitW += width + 4

                                                            Repeater {
                                                                model: root.splitKey(altRow.modelData)
                                                                delegate: Rectangle {
                                                                    required property string modelData
                                                                    implicitWidth: Math.max(20, capText.implicitWidth + 12)
                                                                    implicitHeight: 20
                                                                    radius: root.crSmall
                                                                    color: ThemeBackend.surface0
                                                                    border.color: ThemeBackend.surface1
                                                                    border.width: 1
                                                                    Rectangle {
                                                                        anchors.left: parent.left
                                                                        anchors.right: parent.right
                                                                        anchors.bottom: parent.bottom
                                                                        anchors.margins: 1
                                                                        height: 2
                                                                        radius: 1
                                                                        color: ThemeBackend.crust
                                                                        opacity: 0.6
                                                                    }
                                                                    Text {
                                                                        id: capText
                                                                        anchors.centerIn: parent
                                                                        anchors.verticalCenterOffset: -1
                                                                        text: parent.modelData
                                                                        color: ThemeBackend.text
                                                                        font.family: ThemeBackend.fontFamily
                                                                        font.pixelSize: 11
                                                                        font.weight: Font.DemiBold
                                                                    }
                                                                }
                                                            }

                                                            Text {
                                                                visible: altRow.index < rowItem.modelData.k.split("|").length - 1
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                text: "/"
                                                                leftPadding: 2
                                                                color: ThemeBackend.overlay0
                                                                font.family: ThemeBackend.fontFamily
                                                                font.pixelSize: 12
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: "Gõ để tìm   ·   ↑ ↓ cuộn   ·   Esc / Super+/ để đóng"
                color: ThemeBackend.overlay1
                font.family: ThemeBackend.fontFamily
                font.pixelSize: 11
            }
        }
    }
}
