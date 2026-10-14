import QtQuick

// `.card` (and `.card.hi`): faint raised tile inside a glass panel.
Rectangle {
    property bool hi: false
    radius: 18
    color: Fz.light ? Qt.rgba(1, 1, 1, 0.55) : Fz.fg(hi ? 0.08 : 0.045)
    border.width: 1
    border.color: Fz.line
}
