import QtQuick

// `.em` of EmptyStates.dc.html: a 64px round icon, a title, a short explanation, optionally a command
// line and one button.
Column {
    id: root
    property string icon: ""
    property string title: ""
    property string message: ""
    property string code: ""
    property string button: ""
    property bool buttonPrimary: true
    property color iconColor: Fz.sub
    property color iconBg: Fz.fg(0.06)
    signal clicked()
    spacing: 10
    topPadding: 16; bottomPadding: 16
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: 64; height: 64; radius: 32; color: root.iconBg
        FIcon { anchors.centerIn: parent; name: root.icon; size: 28; color: root.iconColor }
    }
    FText { anchors.horizontalCenter: parent.horizontalCenter; width: Math.min(implicitWidth, root.width); horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap; text: root.title; px: 16; weight: Font.DemiBold }
    FText { visible: root.message !== ""; anchors.horizontalCenter: parent.horizontalCenter; width: Math.min(300, root.width); horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap; lineHeight: 1.45; text: root.message; px: 13; color: Fz.sub }
    Rectangle {
        visible: root.code !== ""
        anchors.horizontalCenter: parent.horizontalCenter
        width: codeText.implicitWidth + 20; height: codeText.implicitHeight + 12; radius: 8
        color: Fz.well(0.3)
        FText { id: codeText; anchors.centerIn: parent; text: root.code; mono: true; px: 12; color: Fz.sub2 }
    }
    FBtn { visible: root.button !== ""; anchors.horizontalCenter: parent.horizontalCenter; kind: root.buttonPrimary ? "pri" : ""; text: root.button; onClicked: root.clicked() }
}
