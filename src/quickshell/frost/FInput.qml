import QtQuick

// `.inp`: text field (40px, well background, glow border on focus). `icon` adds a leading search-style glyph.
Rectangle {
    id: root
    property alias text: field.text
    property string placeholder: ""
    property string icon: ""
    property bool password: false
    property bool reveal: false        // password shown in clear (eye button)
    readonly property bool masked: password && !reveal
    property real fontSize: 14
    property alias input: field
    signal accepted()
    implicitWidth: 220
    implicitHeight: 40
    radius: 12
    color: Fz.well(0.22)
    border.width: 1
    border.color: field.activeFocus ? Fz.glow : Fz.line2

    Row {
        anchors.fill: parent
        anchors.leftMargin: root.icon ? 10 : 14
        anchors.rightMargin: 14
        spacing: 8
        FIcon { visible: root.icon !== ""; name: root.icon; size: 14; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter }
        Item {
            width: parent.width - (root.icon ? 22 : 0)
            height: parent.height
            TextInput {
                id: field
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                // passwords stay in Normal echo with sensitive hints so Unikey passes keys straight through
                // (in Password echo it still composes); the dots are drawn over the transparent text below
                color: root.masked ? "transparent" : Fz.tx
                font.family: Fz.font
                font.pointSize: root.fontSize * 0.75
                selectionColor: root.masked ? "transparent" : Fz.accA(0.35)
                selectedTextColor: root.masked ? "transparent" : Fz.tx
                echoMode: TextInput.Normal
                inputMethodHints: root.password ? (Qt.ImhHiddenText | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase) : Qt.ImhNone
                cursorDelegate: root.masked ? emptyCursor : null
                clip: true
                onAccepted: root.accepted()
            }
            Component { id: emptyCursor; Item {} }
            Text {
                id: dots
                visible: root.masked
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, parent.width - 4); clip: true
                horizontalAlignment: implicitWidth > parent.width - 4 ? Text.AlignRight : Text.AlignLeft
                text: "•".repeat(field.text.length)
                color: Fz.tx; font.family: Fz.font; font.pointSize: root.fontSize * 0.75
            }
            Rectangle {
                visible: root.masked && field.activeFocus && dotCaret.on
                x: dots.width + 1; anchors.verticalCenter: parent.verticalCenter
                width: 1.5; height: root.fontSize + 4; radius: 1; color: Fz.tx
                Timer { id: dotCaret; property bool on: true; interval: 530; repeat: true; running: root.masked && field.activeFocus; onTriggered: on = !on; onRunningChanged: on = true }
            }
            FText { anchors.verticalCenter: parent.verticalCenter; visible: field.text === "" && !field.inputMethodComposing; text: root.placeholder; color: Fz.dim; px: root.fontSize }
        }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.IBeamCursor; onPressed: (e) => { field.forceActiveFocus(); e.accepted = false; } }
}
