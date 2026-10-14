import QtQuick
import Quickshell
import Quickshell.Wayland
import "../"
import "../frost"

// Notification toasts of the Frost design (Notifications.dc.html): 380px glass cards stacked
// 64px from the top and 16px from the right. Progress, screenshot, quick-reply and weather
// notifications get the artboard's dedicated layouts.
PanelWindow {
    id: win
    WlrLayershell.namespace: "qs-toasts"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: replying ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; right: true }
    margins { top: 64 - 40; right: 16 - 40 }
    implicitWidth: 380 + 80
    color: "transparent"
    visible: NotificationManager.activePopupsModel.count > 0 && !NotificationManager.sysPanelOpen
    mask: Region { item: list }

    property bool replying: false
    readonly property bool dnd: { let n = Config.getSetting("notifications", {}); return !!(n && n.dnd); }
    property var store: ({})
    Connections {
        target: NotificationManager
        function onPopupAdded(uid, notif) { let s = win.store; s[uid] = notif; win.store = s; }
    }
    function notif(uid) { return store[uid] || NotificationManager.liveNotifs[uid] || null; }
    function drop(uid) {
        let s = store; delete s[uid]; store = s;
        NotificationManager.removePopup(uid);
    }
    function ago(ts) { let m = Math.floor((Date.now() - ts) / 60000); return m < 1 ? "bây giờ" : m < 60 ? m + " phút" : Math.floor(m / 60) + " giờ"; }
    function kind(m, n) {
        let app = (m.appName || "").toLowerCase();
        if (app === "weather" || app === "thời tiết") return "weather";
        if (n && n.hints && n.hints.value !== undefined) return "progress";
        if (/screenshot|ảnh chụp|screen recorder/.test(app)) return "shot";
        if (n && n.hasInlineReply) return "reply";
        return "plain";
    }
    function icon(app) {
        let a = (app || "").toLowerCase();
        if (/update|pacman|yay|paru/.test(a)) return "t-box";
        if (/screenshot|ảnh chụp|recorder/.test(a)) return "t-image";
        if (/weather|thời tiết/.test(a)) return "t-rain";
        if (/viber|telegram|discord|zalo|messenger|signal|slack|chat|mail/.test(a)) return "t-chat";
        return "q-bell";
    }

    ListView {
        id: list
        x: 40; y: 40
        width: 380
        height: Math.min(contentHeight, win.height - 80)
        interactive: false
        spacing: 10
        model: NotificationManager.activePopupsModel
        add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 180 } NumberAnimation { property: "x"; from: 40; to: 0; duration: 220; easing.type: Easing.OutCubic } }
        displaced: Transition { NumberAnimation { property: "y"; duration: 200; easing.type: Easing.OutCubic } }

        delegate: Item {
            id: d
            required property var model
            required property int index
            readonly property int uid: model.uid || model.latestUid
            readonly property var n: win.notif(uid)
            readonly property string k: win.kind(model, n)
            readonly property bool hidden: win.dnd && model.urgency !== 2
            readonly property int timeout: {
                if (model.urgency === 2) return 0;
                let t = n ? n.expireTimeout : -1;
                return t === 0 ? 0 : (t > 0 ? t : 5000);
            }
            width: 380
            height: hidden ? 0 : card.height
            visible: !hidden

            Timer {
                interval: d.timeout > 0 ? d.timeout : 5000
                running: d.timeout > 0 && !hover.hovered && !reply.input.activeFocus
                onTriggered: win.drop(d.uid)
            }
            Connections { target: d.n || null; ignoreUnknownSignals: true; function onClosed() { win.drop(d.uid); } }
            HoverHandler { id: hover }

            Glass {
                id: card
                width: 380
                height: body.implicitHeight + 24
                radius: 18

                Column {
                    id: body
                    x: 12; y: 12
                    width: 380 - 24
                    spacing: 8

                    Row {
                        width: parent.width
                        spacing: 12
                        Rectangle {
                            width: 38; height: 38; radius: 12
                            color: d.k === "weather" ? Fz.acc : Fz.s0
                            anchors.verticalCenter: d.k === "weather" ? parent.verticalCenter : undefined
                            FIcon { anchors.centerIn: parent; name: win.icon(d.model.appName); color: d.k === "weather" ? Fz.ink : Fz.acc }
                        }
                        Column {
                            width: parent.width - 38 - 26 - 24
                            spacing: d.k === "progress" ? 6 : 2
                            anchors.verticalCenter: d.k === "weather" ? parent.verticalCenter : undefined
                            FText { visible: d.k !== "weather"; width: parent.width; elide: Text.ElideRight; text: d.model.appName + " · " + win.ago(d.model.timestamp); color: Fz.sub; px: 11.5 }
                            FText { width: parent.width; elide: Text.ElideRight; text: d.model.summary; px: 14; weight: Font.DemiBold }
                            FText {
                                visible: d.k !== "progress" && d.model.body !== ""
                                width: parent.width; wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight
                                text: d.model.body; textFormat: Text.PlainText
                                color: Fz.sub2; px: d.k === "weather" ? 12.5 : 13
                            }
                            FBar { visible: d.k === "progress"; width: parent.width; value: d.n && d.n.hints ? Number(d.n.hints.value) / 100 : 0 }
                            FText { visible: d.k === "progress"; width: parent.width; elide: Text.ElideRight; mono: true; text: d.model.body; color: Fz.sub; px: 11.5 }
                        }
                        FIconBtn { width: 26; height: 26; ghost: true; icon: "t-x"; iconSize: 13; label: "Đóng"; onClicked: win.drop(d.uid) }
                    }

                    // screenshot preview and actions
                    RoundImage {
                        visible: d.k === "shot" && source != ""
                        width: parent.width; height: visible ? 120 : 0; radius: 12
                        source: { let p = d.n && d.n.hints ? (d.n.hints["image-path"] || "") : ""; return p ? (p.startsWith("/") ? "file://" + p : p) : (d.model.image || ""); }
                    }
                    Row {
                        visible: d.k === "shot"
                        width: parent.width
                        spacing: 6
                        readonly property string file: d.n && d.n.hints ? String(d.n.hints["image-path"] || "").replace(/^file:\/\//, "") : ""
                        FBtn { width: (parent.width - 12) / 3; height: 32; fontSize: 12.5; kind: "pri"; text: "Chỉnh sửa"
                               onClicked: { if (d.n && d.n.actions && d.n.actions.length) d.n.actions[0].invoke(); win.drop(d.uid); } }
                        FBtn { width: (parent.width - 12) / 3; height: 32; fontSize: 12.5; text: "Mở thư mục"
                               onClicked: { if (parent.file) Quickshell.execDetached(["xdg-open", parent.file.replace(/\/[^/]*$/, "")]); win.drop(d.uid); } }
                        FBtn { width: (parent.width - 12) / 3; height: 32; fontSize: 12.5; text: "Xóa"
                               onClicked: { if (parent.file) Quickshell.execDetached(["rm", "-f", "--", parent.file]); win.drop(d.uid); } }
                    }

                    // quick reply
                    Row {
                        visible: d.k === "reply"
                        width: parent.width
                        spacing: 6
                        FInput {
                            id: reply
                            width: parent.width - 6 - 36; height: 36; fontSize: 13
                            placeholder: d.n && d.n.inlineReplyPlaceholder ? d.n.inlineReplyPlaceholder : "Trả lời nhanh…"
                            input.onActiveFocusChanged: win.replying = input.activeFocus
                            onAccepted: send.clicked()
                        }
                        FIconBtn { id: send; on: true; icon: "t-send"; iconSize: 15; label: "Gửi"
                                   onClicked: { if (d.n && reply.text.trim() !== "") { d.n.sendInlineReply(reply.text.trim()); win.drop(d.uid); } } }
                    }

                    // other actions
                    Row {
                        readonly property var acts: d.n && d.n.actions ? d.n.actions.filter(a => a.identifier !== "default" && a.identifier !== "inline-reply") : []
                        visible: (d.k === "plain" || d.k === "progress") && acts.length > 0
                        spacing: 6
                        Repeater {
                            model: parent.acts.slice(0, 3)
                            delegate: FBtn { required property var modelData; required property int index
                                height: 30; fontSize: 12; padX: 12; kind: index === 0 ? "pri" : ""; text: modelData.text
                                onClicked: { modelData.invoke(); win.drop(d.uid); } }
                        }
                    }
                }
                MouseArea {
                    z: -1
                    anchors.fill: parent
                    onClicked: { let def = d.n && d.n.actions ? d.n.actions.find(a => a.identifier === "default") : null; if (def) def.invoke(); win.drop(d.uid); }
                }
            }
        }
    }
}
