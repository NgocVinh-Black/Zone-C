import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../"
import "../frost"

// File chooser of the Frost design (FilePicker.dc.html) serving xdg-desktop-portal requests.
// scripts/portal/zonec_portal.py writes a request JSON and calls `portal fileChooser <file>`;
// the answer goes to <file>.out as {"paths": [...]} or {"cancel": true}.
PanelWindow {
    id: win
    property bool open: false
    property string reqFile: ""
    visible: open
    WlrLayershell.namespace: "zone-c-portal"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    function answer(obj) {
        Quickshell.execDetached(["bash", "-c", "printf '%s' \"$2\" > \"$1.tmp\" && mv \"$1.tmp\" \"$1\"", "_", reqFile + ".out", JSON.stringify(obj)]);
        open = false;
    }
    Process {
        id: reader
        stdout: StdioCollector {
            onStreamFinished: {
                let r; try { r = JSON.parse(this.text); } catch (e) { win.answer({ cancel: true }); return; }
                picker.subtitle = r.app || "Ứng dụng";
                picker.modeSwitch = false;
                win.open = true;
                picker.show(r.title || (r.mode === "save" ? "Lưu tệp" : r.mode === "folder" ? "Chọn thư mục" : "Mở tệp"),
                            r.exts || [], r.folder || "", r.mode || "open", r.name || "");
                if (r.filterLabel) picker.filterLabel = r.filterLabel;
            }
        }
    }
    IpcHandler {
        target: "portal"
        function fileChooser(file: string): void { win.reqFile = file; reader.command = ["cat", file]; reader.running = true; }
    }

    Rectangle { anchors.fill: parent; color: Fz.surf(0.2) }
    FFilePicker {
        id: picker
        onAccepted: (path) => win.answer({ paths: [path] })
        onCanceled: win.answer({ cancel: true })
    }
}
