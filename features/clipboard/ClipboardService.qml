pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core.config
import "ClipboardLogic.js" as Logic
import "schema.js" as Schema

// Clipboard history from cliphist. The list is re-read whenever the popup opens,
// so nothing is polled while it is closed.
Singleton {
    id: root

    readonly property var settings: Config.feature("clipboard", Schema.fields)

    property var entries: []
    property bool loading: false

    function refresh(): void {
        loading = true;
        reader.running = true;
    }

    function search(query: string): var {
        return Logic.filter(entries, query);
    }

    // cliphist identifies an entry by the whole "<id>\t<preview>" line it printed,
    // so the line goes back in on stdin rather than being picked apart.
    function copy(entry: var): void {
        if (entry)
            Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | cliphist decode | wl-copy", "sh", entry.line]);
    }

    function remove(entry: var): void {
        if (!entry)
            return;
        Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | cliphist delete", "sh", entry.line]);
        entries = entries.filter(other => other.id !== entry.id);
    }

    function wipe(): void {
        Quickshell.execDetached(["cliphist", "wipe"]);
        entries = [];
    }

    Process {
        id: reader

        command: ["cliphist", "list"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.entries = Logic.parse(text).slice(0, root.settings.maxEntries);
                root.loading = false;
            }
        }

        onExited: code => {
            if (code !== 0) {
                console.warn("[zone-c clipboard] cliphist list failed with code", code);
                root.loading = false;
            }
        }
    }
}
