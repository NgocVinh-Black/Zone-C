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
    // Settings → Thông báo "Vị trí thông báo nổi": top/bottom + left/center/right
    readonly property string pos: Config.getSetting("notifications.position", "top right") || "top right"
    readonly property string hpos: pos.indexOf("left") !== -1 ? "left" : pos.indexOf("center") !== -1 ? "center" : "right"
    readonly property bool atBottom: pos.indexOf("bottom") === 0
    anchors { top: true; bottom: true; right: hpos !== "left"; left: hpos !== "right" }
    // keep clear of the bar wherever it sits (52px tall on top/bottom, 60px wide on the sides)
    readonly property string barPos: Config.getSetting("bar.position", "top")
    margins {
        top: (barPos === "top" ? 64 : 16) - 40
        bottom: (barPos === "bottom" ? 64 : 16) - 40
        right: hpos === "right" ? (barPos === "right" ? 76 : 16) - 40 : 0
        left: hpos === "left" ? (barPos === "left" ? 76 : 16) - 40 : 0
    }
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
        if (n && n.hints && n.hints["x-zone-c-alert"]) return "alert";
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
        x: win.hpos === "center" ? (win.width - width) / 2 : 40
        y: win.atBottom ? win.height - 40 - height : 40
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
            // Alerts.dc.html cards: bat / usb / restart / hot
            readonly property string ak: k === "alert" ? String(n.hints["x-zone-c-alert"]) : ""
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
                width: d.ak ? 390 : 380
                height: body.implicitHeight + (d.ak ? 32 : 24)
                radius: d.ak ? 20 : 18
                // low battery is a `.toast.solid` with a red edge
                color: d.ak === "bat" ? Fz.mantle : Fz.glass
                borderColor: d.ak === "bat" ? Fz.redA(0.4) : (Fz.light ? Fz.glassEdge : Fz.line)

                Column {
                    id: body
                    x: d.ak ? 16 : 12; y: d.ak ? 16 : 12
                    width: card.width - 2 * x
                    spacing: d.ak ? 12 : 8

                    Row {
                        width: parent.width
                        spacing: 12
                        Rectangle {
                            width: d.ak ? 36 : 38; height: d.ak ? 36 : 38; radius: d.ak ? 11 : 12
                            color: d.ak === "bat" ? Fz.redA(0.16) : d.ak === "hot" ? Fz.yellowA(0.14) : d.ak === "usb" ? Fz.fg(0.07) : (d.k === "weather" || d.ak === "restart") ? Fz.acc : Fz.s0
                            anchors.verticalCenter: (d.k === "weather" || d.ak) ? parent.verticalCenter : undefined
                            FIcon {
                                anchors.centerIn: parent
                                name: d.ak ? "Alerts:a-" + d.ak : win.icon(d.model.appName)
                                size: d.ak === "bat" ? 22 : 17
                                color: d.ak === "bat" ? Fz.red : d.ak === "hot" ? Fz.yellow : (d.k === "weather" || d.ak === "restart") ? Fz.ink : Fz.acc
                            }
                        }
                        Column {
                            width: d.ak ? parent.width - 36 - 12 : parent.width - 38 - 26 - 24
                            spacing: d.k === "progress" ? 6 : 2
                            anchors.verticalCenter: (d.k === "weather" || d.ak) ? parent.verticalCenter : undefined
                            FText { visible: d.k !== "weather" && !d.ak; width: parent.width; elide: Text.ElideRight; text: d.model.appName + " · " + win.ago(d.model.timestamp); color: Fz.sub; px: 11.5 }
                            FText { width: parent.width; elide: Text.ElideRight; text: d.model.summary; px: d.ak && d.ak !== "hot" ? 14.5 : 14; weight: Font.DemiBold }
                            FText {
                                visible: d.k !== "progress" && d.model.body !== ""
                                width: parent.width; wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight
                                text: d.model.body; textFormat: Text.PlainText
                                color: Fz.sub2; px: d.k === "weather" || d.ak ? 12.5 : 13; font.family: d.ak === "usb" ? Fz.mono : Fz.font
                            }
                            FBar { visible: d.k === "progress"; width: parent.width; value: d.n && d.n.hints ? Number(d.n.hints.value) / 100 : 0 }
                            FText { visible: d.k === "progress"; width: parent.width; elide: Text.ElideRight; mono: true; text: d.model.body; color: Fz.sub; px: 11.5 }
                        }
                        FIconBtn { visible: !d.ak; width: 26; height: 26; ghost: true; icon: "t-x"; iconSize: 13; label: "Đóng"; onClicked: win.drop(d.uid) }
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
                        visible: (d.k === "plain" || d.k === "progress" || d.k === "alert") && acts.length > 0
                        spacing: d.ak ? 8 : 6
                        Repeater {
                            model: parent.acts.slice(0, 3)
                            delegate: FBtn { required property var modelData; required property int index
                                width: d.ak ? (body.width - 8) / 2 : implicitWidth
                                height: d.ak ? 36 : 30; fontSize: d.ak ? 13 : 12; padX: 12; kind: index === 0 && d.ak !== "usb" ? "pri" : ""; text: modelData.text
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
