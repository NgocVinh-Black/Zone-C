import QtQuick

// `.inp`: text field (40px, well background, glow border on focus). `icon` adds a leading search-style glyph.
Rectangle {
    id: root
    property alias text: field.text
    property string placeholder: ""
    property string icon: ""
    property bool password: false
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
                color: Fz.tx
                font.family: Fz.font
                font.pointSize: root.fontSize * 0.75
                selectionColor: Fz.accA(0.35)
                selectedTextColor: Fz.tx
                echoMode: root.password ? TextInput.Password : TextInput.Normal
                // passwords: keep input methods (Unikey) from composing in the field
                inputMethodHints: root.password ? (Qt.ImhHiddenText | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhPreferLatin) : Qt.ImhNone
                clip: true
                onAccepted: root.accepted()
            }
            FText { anchors.verticalCenter: parent.verticalCenter; visible: field.text === "" && !field.inputMethodComposing; text: root.placeholder; color: Fz.dim; px: root.fontSize }
        }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.IBeamCursor; onPressed: (e) => { field.forceActiveFocus(); e.accepted = false; } }
}
