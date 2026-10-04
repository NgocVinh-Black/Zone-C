pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Chay bt_agent.py de xac nhan ghep doi Bluetooth ngay trong panel thay vi thong bao.
Item {
    id: root

    // { id, type: confirm|pin|passkey|authorize|display, device, address, name, passkey, entered }
    property var request: null
    readonly property bool active: request !== null
    readonly property bool needsInput: active && (request.type === "pin" || request.type === "passkey")

    signal requestStarted()

    function respond(ok, value) {
        if (!root.request) return;
        if (root.request.type !== "display") {
            agentProc.write(JSON.stringify({ id: root.request.id, ok: ok, value: value !== undefined ? String(value) : "" }) + "\n");
        }
        root.request = null;
    }

    function clearFor(address) {
        if (root.request && root.request.address === address) root.request = null;
    }

    function handleLine(line) {
        let msg;
        try { msg = JSON.parse(line); } catch (e) { return; }
        if (msg.type === "ready") return;
        if (msg.type === "cancel") { root.request = null; return; }
        let isNew = !root.request || root.request.address !== msg.address || root.request.type !== msg.type;
        root.request = msg;
        if (isNew) root.requestStarted();
    }

    Process {
        id: agentProc
        command: ["python3", Qt.resolvedUrl("bt_agent.py").toString().replace("file://", "")]
        running: true
        stdinEnabled: true
        stdout: SplitParser { onRead: data => root.handleLine(data) }
        onExited: {
            root.request = null;
            restartTimer.restart();
        }
    }

    Timer {
        id: restartTimer
        interval: 3000
        onTriggered: agentProc.running = true
    }
}
