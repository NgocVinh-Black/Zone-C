import QtQuick
import qs.core.state
import qs.core.theme

// The rounded search box the launcher and clipboard popups type into. It owns the
// keyboard while its popup is open and forwards the navigation keys, so the list
// below never has to take focus away from the cursor.
Rectangle {
    id: root

    property alias text: input.text
    property string placeholder: ""
    property string icon: String.fromCodePoint(0xF0349)
    property color accent: Colours.blue
    property int count: 0

    // Up/down/page keys, as -1/+1 steps and whole-page jumps.
    signal moved(int delta)
    signal accepted
    signal removed

    readonly property bool empty: input.text === ""

    function take(): void {
        input.forceActiveFocus();
    }

    function clear(): void {
        input.text = "";
    }

    implicitHeight: UiScale.s(58)
    radius: UiScale.s(16)
    color: Colours.alpha(Colours.white, 0.05)
    border.color: input.activeFocus ? Colours.alpha(root.accent, 0.5) : Colours.alpha(Colours.white, 0.1)
    border.width: 1

    Behavior on border.color {
        ColorAnim {}
    }

    Icon {
        id: glyph

        anchors.left: parent.left
        anchors.leftMargin: UiScale.s(18)
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon
        font.pixelSize: Tokens.font.size.title
        color: root.empty ? Colours.subtext0 : root.accent

        Behavior on color {
            ColorAnim {}
        }
    }

    TextInput {
        id: input

        anchors.left: glyph.right
        anchors.leftMargin: UiScale.s(14)
        anchors.right: counter.left
        anchors.rightMargin: UiScale.s(12)
        anchors.verticalCenter: parent.verticalCenter
        color: Colours.text
        font.family: Tokens.font.text
        font.pixelSize: Tokens.font.size.large
        font.weight: Font.Bold
        selectionColor: Colours.alpha(root.accent, 0.35)
        selectedTextColor: Colours.text
        clip: true
        focus: true
        renderType: Text.NativeRendering

        onAccepted: root.accepted()

        Keys.onUpPressed: root.moved(-1)
        Keys.onDownPressed: root.moved(1)
        Keys.onPressed: event => {
            if (event.key === Qt.Key_PageUp) {
                root.moved(-5);
                event.accepted = true;
            } else if (event.key === Qt.Key_PageDown) {
                root.moved(5);
                event.accepted = true;
            } else if (event.key === Qt.Key_Delete && (event.modifiers & Qt.ShiftModifier)) {
                root.removed();
                event.accepted = true;
            } else if (event.key === Qt.Key_Tab) {
                root.moved(1);
                event.accepted = true;
            }
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.empty
            text: root.placeholder
            font.pixelSize: Tokens.font.size.large
            font.weight: Font.Normal
            color: Colours.subtext1
        }
    }

    StyledText {
        id: counter

        anchors.right: parent.right
        anchors.rightMargin: UiScale.s(18)
        anchors.verticalCenter: parent.verticalCenter
        visible: root.count > 0
        text: root.count
        font.pixelSize: Tokens.font.size.label
        font.weight: Font.Black
        color: Colours.subtext1
    }
}
