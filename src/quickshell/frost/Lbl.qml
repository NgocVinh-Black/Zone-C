import QtQuick

// `.lbl`: bold 14px label with an optional 12.5px sub line.
Column {
    property string title: ""
    property string sub: ""
    property color titleColor: Fz.tx
    spacing: 2
    FText { width: parent.width; elide: Text.ElideRight; text: parent.title; px: 14; weight: Font.Medium; color: parent.titleColor }
    FText { width: parent.width; elide: Text.ElideRight; visible: text !== ""; text: parent.sub; px: 12.5; color: Fz.sub }
}
