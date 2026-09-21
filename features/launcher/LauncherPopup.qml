import QtQuick
import QtQuick.Layouts
import qs.core.popup
import qs.core.state
import qs.core.theme
import qs.core.ui
import qs.features.launcher
import "LauncherLogic.js" as Logic

// Application launcher: a search box over a ranked list. Typing never leaves the
// box, so the arrow keys move the selection while the cursor stays put.
PopupBase {
    id: root

    readonly property var results: LauncherService.search(field.text)
    property int selected: 0

    readonly property color accent: Colours.blue

    blobPrimary: accent
    blobSecondary: Colours.mauve
    blobPrimaryOpacity: 0.07
    blobSecondaryOpacity: 0.05

    onResultsChanged: selected = 0

    function move(delta: int): void {
        selected = Logic.clampIndex(selected + delta, results.length);
        list.positionViewAtIndex(selected, ListView.Contain);
    }

    function launch(index: int): void {
        const item = results[index];
        if (!item)
            return;
        LauncherService.launch(item);
        ShellState.close();
    }

    Component.onCompleted: field.take()

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

        SearchField {
            id: field

            Layout.fillWidth: true
            accent: root.accent
            placeholder: LauncherService.settings.placeholder
            count: root.results.length
            opacity: introHeader.value

            transform: Translate {
                y: UiScale.s(-20) * (1 - introHeader.value)
            }

            onMoved: delta => root.move(delta)
            onAccepted: root.launch(root.selected)
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
                    text: String.fromCodePoint(0xF0349)
                    font.pixelSize: UiScale.s(32)
                    color: Colours.surface2
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No applications match"
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
                highlightMoveDuration: Tokens.anim.fast
                boundsBehavior: Flickable.StopAtBounds

                delegate: AppRow {
                    required property var modelData
                    required property int index

                    width: ListView.view.width
                    item: modelData
                    accent: root.accent
                    selected: index === root.selected

                    onActivated: root.launch(index)
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
                    { key: "↵", label: "open" },
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
