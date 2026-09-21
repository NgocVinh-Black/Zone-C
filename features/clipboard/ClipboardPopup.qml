import QtQuick
import QtQuick.Layouts
import qs.core.popup
import qs.core.state
import qs.core.theme
import qs.core.ui
import qs.features.clipboard
import "ClipboardLogic.js" as Logic

// Clipboard history: the same search-over-a-list shape as the launcher, with
// Shift+Delete to drop an entry and a wipe button for the whole history.
PopupBase {
    id: root

    readonly property var results: ClipboardService.search(field.text)
    property int selected: 0

    readonly property color accent: Colours.mauve

    blobPrimary: accent
    blobSecondary: Colours.blue
    blobPrimaryOpacity: 0.07
    blobSecondaryOpacity: 0.05

    onResultsChanged: selected = Logic.clampIndex(selected, results.length)

    function move(delta: int): void {
        selected = Logic.clampIndex(selected + delta, results.length);
        list.positionViewAtIndex(selected, ListView.Contain);
    }

    function copy(index: int): void {
        const entry = results[index];
        if (!entry)
            return;
        ClipboardService.copy(entry);
        ShellState.close();
    }

    function remove(index: int): void {
        const entry = results[index];
        if (entry)
            ClipboardService.remove(entry);
    }

    Component.onCompleted: {
        ClipboardService.refresh();
        field.take();
    }

    Reveal {
        id: introHeader
        delay: 80
    }
    Reveal {
        id: introList
        delay: 200
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.popup.padding
        spacing: UiScale.s(18)

        RowLayout {
            Layout.fillWidth: true
            spacing: UiScale.s(12)
            opacity: introHeader.value

            transform: Translate {
                y: UiScale.s(-20) * (1 - introHeader.value)
            }

            SearchField {
                id: field

                Layout.fillWidth: true
                accent: root.accent
                icon: String.fromCodePoint(0xF0192)
                placeholder: ClipboardService.settings.placeholder
                count: root.results.length

                onMoved: delta => root.move(delta)
                onAccepted: root.copy(root.selected)
                onRemoved: root.remove(root.selected)
            }

            IconButton {
                Layout.preferredWidth: UiScale.s(48)
                Layout.preferredHeight: UiScale.s(48)
                icon: String.fromCodePoint(0xF05E8)
                iconSize: Tokens.font.size.title
                colour: Colours.subtext0
                hoverColour: Colours.red

                onClicked: ClipboardService.wipe()
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            opacity: introList.value

            transform: Translate {
                y: UiScale.s(20) * (1 - introList.value)
            }

            ColumnLayout {
                anchors.centerIn: parent
                visible: root.results.length === 0
                spacing: UiScale.s(10)

                Icon {
                    Layout.alignment: Qt.AlignHCenter
                    text: String.fromCodePoint(0xF0192)
                    font.pixelSize: UiScale.s(32)
                    color: Colours.surface2
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: ClipboardService.loading ? "Reading clipboard history" : "Clipboard history is empty"
                    font.weight: Font.Normal
                    color: Colours.overlay0
                }
            }

            ListView {
                id: list

                anchors.fill: parent
                clip: true
                spacing: UiScale.s(8)
                model: root.results
                currentIndex: root.selected
                boundsBehavior: Flickable.StopAtBounds

                delegate: ClipRow {
                    required property var modelData
                    required property int index

                    width: ListView.view.width
                    entry: modelData
                    accent: root.accent
                    selected: index === root.selected

                    onActivated: root.copy(index)
                    onRemoved: root.remove(index)
                    onHovered: root.selected = index
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: UiScale.s(18)
            opacity: introList.value

            Repeater {
                model: [
                    { key: "↑ ↓", label: "select" },
                    { key: "↵", label: "copy" },
                    { key: "⇧ del", label: "remove" },
                    { key: "esc", label: "close" }
                ]

                delegate: RowLayout {
                    required property var modelData

                    spacing: UiScale.s(6)

                    StyledText {
                        text: parent.modelData.key
                        font.pixelSize: Tokens.font.size.tiny
                        font.weight: Font.Black
                        color: Colours.subtext0
                    }

                    StyledText {
                        text: parent.modelData.label
                        font.pixelSize: Tokens.font.size.tiny
                        font.weight: Font.Normal
                        color: Colours.subtext1
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }
        }
    }
}
