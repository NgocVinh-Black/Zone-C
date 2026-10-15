import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../"
import "../frost"

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
            { k: "Super+.", d: "Emoji & ký tự" },
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
        { col: 2, icon: "󰄛", title: "Con mèo (float-cat)", accent: "yellow", rows: [
            { k: "Super+Shift+K|Phím Copilot", d: "Bật / tắt con mèo" },
            { k: "Super+K", d: "Rồi kéo bằng chuột để dời chỗ" } ] },
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
            { k: "Alt+Tab", d: "Chuyển ứng dụng (thả Alt để mở)" },
            { k: "Shift+Alt+Tab", d: "Chuyển cửa sổ ngược lại" },
            { k: "Super+,", d: "Gộp / bỏ nhóm" },
            { k: "Super+U", d: "Tách khỏi nhóm" },
            { k: "Super+Shift+,", d: "Khoá nhóm" },
            { k: "Ctrl+Alt+Tab|Ctrl+Shift+Alt+Tab", d: "Tab kế tiếp / trước" } ] },
        { col: 2, icon: "󰍺", title: "Workspace", accent: "green", rows: [
            { k: "Super+Tab", d: "Tổng quan cửa sổ" },
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
    visible: active
    color: "transparent"

    IpcHandler {
        target: "keybinds"
        function toggle(): void { root.toggle(); }
        function open(): void { root.open(); }
        function close(): void { root.close(); }
        function isOpen(): bool { return root.active; }
    }

    Timer { id: focusTimer; interval: 30; onTriggered: searchInput.forceActiveFocus() }

    // Keybinds.dc.html: blurred wallpaper under the night scrim, title + search, cards in three columns
    Image {
        anchors.fill: parent; anchors.margins: -60
        source: { let p = Wallpaper.getWallpaperPath(""); return p && !ZoneStyle.isVideo(p) ? "file://" + p : ""; }
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: 960
        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 64; blurMultiplier: 1.6; saturation: 0.1 }
    }
    Rectangle { anchors.fill: parent; color: Fz.scrimNight; MouseArea { anchors.fill: parent; onClicked: root.close() } }

    Item {
        id: page
        x: 80 * root.width / 1440
        y: 60
        width: root.width - 2 * x
        height: root.height - 120

        Row {
            id: header
            width: parent.width
            spacing: 16
            FText { width: parent.width - 16 * 2 - search.width - hint.width; text: "Phím tắt"; px: 28; weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
            Rectangle {
                id: search
                width: 360; height: 44; radius: 14
                color: Fz.well(0.3); border.width: 1; border.color: Fz.line2
                anchors.verticalCenter: parent.verticalCenter
                Row {
                    x: 14; anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    FIcon { name: "kb-search"; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter }
                    Item {
                        width: 360 - 28 - 27; height: 22; anchors.verticalCenter: parent.verticalCenter
                        TextInput {
                            id: searchInput; anchors.fill: parent; verticalAlignment: TextInput.AlignVCenter
                            color: Fz.tx; font.family: Fz.font; font.pointSize: 14.5 * 0.75; clip: true
                            onTextChanged: root.query = text
                            Keys.onEscapePressed: root.close()
                        }
                        FText { anchors.verticalCenter: parent.verticalCenter; visible: searchInput.text === ""; text: "Tìm phím tắt…"; color: Fz.dim; px: 14.5 }
                    }
                }
            }
            Row {
                id: hint
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                FKbd { text: "Super" } FKbd { text: "/" }
                FText { text: "để đóng"; px: 13; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter }
            }
        }

        Flickable {
            y: header.height + 20
            width: parent.width
            height: parent.height - y
            contentHeight: cols.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Row {
                id: cols
                width: parent.width
                spacing: 16
                Repeater {
                    model: 3
                    delegate: Column {
                        required property int index
                        readonly property int colIndex: index
                        width: (cols.width - 32) / 3
                        spacing: 16
                        Repeater {
                            model: root.sections.filter(s => s.col === colIndex && s.rows.some(r => root.rowMatches(r)))
                            delegate: Glass {
                                required property var modelData
                                width: parent.width
                                height: sc.implicitHeight + 32
                                radius: 20
                                Column {
                                    id: sc
                                    x: 18; y: 16
                                    width: parent.width - 36
                                    Caps { px: 11; bottomPadding: 6; text: modelData.title }
                                    Repeater {
                                        model: modelData.rows.filter(r => root.rowMatches(r))
                                        delegate: Item {
                                            required property var modelData
                                            required property int index
                                            width: sc.width
                                            height: Math.max(36, label.implicitHeight + 14)
                                            Rectangle { visible: index > 0; width: parent.width; height: 1; color: Fz.fg(0.06) }
                                            FText { id: label; width: parent.width - keys.width - 10; wrapMode: Text.Wrap; text: modelData.d; px: 13.5; color: Fz.sub2; anchors.verticalCenter: parent.verticalCenter }
                                            Row {
                                                id: keys
                                                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                                spacing: 6
                                                Repeater {
                                                    model: modelData.k.split("|")
                                                    delegate: FKbd { required property var modelData; text: modelData.split("+").join(" + ").replace(/ \+  \+ /g, " + +") }
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
