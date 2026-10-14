import QtQuick

// `.chip` with kinds ok / warn / bad / acc.
Rectangle {
    id: root
    property string text: ""
    property string kind: ""
    property string icon: ""
    implicitWidth: row.implicitWidth + 16
    implicitHeight: 21
    radius: 7
    color: kind === "ok" ? Fz.greenA(0.14) : kind === "warn" ? Fz.yellowA(0.14) : kind === "bad" ? Fz.redA(0.14) : kind === "acc" ? Fz.acc : Fz.fg(0.08)
    readonly property color fgColor: kind === "ok" ? Fz.green : kind === "warn" ? Fz.yellow : kind === "bad" ? Fz.red : kind === "acc" ? Fz.ink : Fz.sub2
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 5
        FIcon { visible: root.icon !== ""; name: root.icon; size: 13; color: root.fgColor; anchors.verticalCenter: parent.verticalCenter }
        FText { text: root.text; px: 11.5; font.weight: Font.DemiBold; color: root.fgColor; anchors.verticalCenter: parent.verticalCenter }
    }
}
