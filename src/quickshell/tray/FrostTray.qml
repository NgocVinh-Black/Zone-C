import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import "../"
import "../frost"

// System tray of the Frost design (TrayMenu.dc.html): a 4-column grid of tray apps under the bar
// and the selected app's menu next to it. Opened from the bar (right-click on the clipboard pill).
PanelWindow {
    id: win
    property bool open: false
    visible: open
    WlrLayershell.namespace: "qs-tray"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    readonly property var items: SystemTray.items ? (SystemTray.items.values || []) : []
    property var sel: null
    property var menuStack: []          // QsMenuHandle path into submenus
    readonly property var curMenu: menuStack.length ? menuStack[menuStack.length - 1] : (sel ? sel.menu : null)

    function show() { sel = items.length ? items[0] : null; menuStack = []; open = true; }
    Connections {
        target: Fz
        function onOpenRequest(name, arg) { if (name === "tray") win.open ? (win.open = false) : win.show(); }
    }
    IpcHandler { target: "tray"; function toggle(): void { win.open ? (win.open = false) : win.show(); } }

    function glyph(it) {
        let s = ((it.id || "") + " " + (it.title || "")).toLowerCase();
        if (/viber|telegram|discord|zalo|signal|slack|chat/.test(s)) return "t-chat";
        if (/fcitx|ibus|keyboard|input/.test(s)) return "t-kbd";
        if (/syncthing|sync/.test(s)) return "t-sync";
        if (/nextcloud|dropbox|drive|cloud|owncloud/.test(s)) return "t-cloud";
        if (/flameshot|screenshot|spectacle/.test(s)) return "t-shot";
        if (/cat|claude/.test(s)) return "t-cat";
        return "";
    }
    function label(it) { return it.title || it.tooltipTitle || it.id || Fz.tr("Ứng dụng"); }
    function status(it) { return it.tooltipDescription || it.tooltipTitle || (it.status === Status.NeedsAttention ? Fz.tr("Cần chú ý") : Fz.tr("Đang chạy")); }

    MouseArea { anchors.fill: parent; onClicked: win.open = false }
    Shortcut { sequence: "Escape"; enabled: win.open; onActivated: win.open = false }

    // `.glass` tray grid, 470px from the right edge under the bar
    Glass {
        id: grid
        x: parent.width - 470 - width
        y: 58
        radius: 18
        width: gcol.implicitWidth + 16
        height: gcol.implicitHeight + 16
        MouseArea { anchors.fill: parent }
        Column {
            id: gcol
            x: 8; y: 8
            spacing: 8
            Caps { px: 10.5; leftPadding: 6; topPadding: 2; text: Fz.tr("Khay hệ thống") }
            Grid {
                columns: 4
                spacing: 4
                Repeater {
                    model: win.items
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool on: win.sel === modelData
                        width: 38; height: 38; radius: 11
                        color: on || tiMouse.containsMouse ? Fz.fg(0.1) : "transparent"
                        FIcon { visible: win.glyph(modelData) !== ""; anchors.centerIn: parent; name: win.glyph(modelData); color: parent.on ? Fz.tx : Fz.sub2 }
                        Image { visible: win.glyph(modelData) === ""; anchors.centerIn: parent; width: 18; height: 18; source: modelData.icon; sourceSize: Qt.size(36, 36) }
                        Rectangle { visible: modelData.status === Status.NeedsAttention; x: parent.width - 14; y: 7; width: 7; height: 7; radius: 4; color: Fz.red }
                        MouseArea {
                            id: tiMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                            onClicked: (e) => { if (e.button === Qt.MiddleButton) modelData.secondaryActivate(); else { win.sel = modelData; win.menuStack = []; } }
                            onDoubleClicked: { modelData.activate(); win.open = false; }
                        }
                        Accessible.name: win.label(modelData)
                    }
                }
            }
            FText { visible: win.items.length === 0; leftPadding: 6; text: Fz.tr("Không có ứng dụng nào trong khay"); px: 12.5; color: Fz.sub }
        }
    }

    // selected app's menu
    QsMenuOpener { id: opener; menu: win.curMenu }
    FMenu {
        id: trayMenu
        visible: win.sel !== null
        x: parent.width - 330 - width
        y: 160

        Row {
            leftPadding: 10; topPadding: 8; bottomPadding: 10
            spacing: 10
            Ico { width: 32; height: 32; radius: 10; on: true; iconSize: 16; icon: win.sel && win.glyph(win.sel) !== "" ? win.glyph(win.sel) : "t-open" }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                FText { text: win.sel ? win.label(win.sel) : ""; px: 13.5; weight: Font.DemiBold }
                FText { text: win.sel ? win.status(win.sel) : ""; px: 11.5; color: Fz.sub }
            }
        }
        FMenuItem { visible: win.menuStack.length > 0; icon: "t-chev"; text: Fz.tr("Quay lại"); onTriggered: win.menuStack = win.menuStack.slice(0, -1) }
        FMenuItem { visible: win.menuStack.length === 0 && win.sel !== null; icon: "t-open"; text: Fz.tr("Mở ") + (win.sel ? win.label(win.sel) : ""); onTriggered: { win.sel.activate(); win.open = false; } }
        Repeater {
            model: opener.children
            delegate: Loader {
                required property var modelData
                width: parent ? parent.width : 240
                sourceComponent: modelData.isSeparator ? sepC : itemC
                Component { id: sepC; FMenuSep {} }
                Component {
                    id: itemC
                    FMenuItem {
                        text: modelData.text.replace(/_/g, "")
                        image: modelData.icon || ""
                        chevron: modelData.hasChildren
                        opacity: modelData.enabled ? 1 : 0.45
                        hint: modelData.checkState === Qt.Checked ? "✓" : ""
                        onTriggered: {
                            if (!modelData.enabled) return;
                            if (modelData.hasChildren) { win.menuStack = win.menuStack.concat([modelData]); return; }
                            modelData.triggered();
                            win.open = false;
                        }
                    }
                }
            }
        }
        // "Thoát": the app's own quit entry when its menu has one
        readonly property var quitEntry: (opener.children ? (opener.children.values || []) : []).find(e => !e.isSeparator && /^(quit|exit|thoát|đóng|close)\b/i.test(e.text.replace(/_/g, ""))) || null
        FMenuSep { visible: trayMenu.quitEntry !== null && win.menuStack.length === 0 }
        FMenuItem {
            visible: trayMenu.quitEntry !== null && win.menuStack.length === 0
            danger: true; icon: "t-x"
            text: Fz.tr("Thoát ") + (win.sel ? win.label(win.sel) : "")
            onTriggered: { trayMenu.quitEntry.triggered(); win.open = false; }
        }
    }
}
