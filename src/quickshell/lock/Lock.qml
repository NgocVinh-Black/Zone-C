import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtMultimedia
import QtCore
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import "../"
import "../reusables"
import "../notifications"

Scope {
    id: root

    property string freezeTimestamp: ""
    property bool isUnlocking: false

    property bool isNiri: false
    property bool isSway: false
    property string kbLayout: "US"
    property int connectedScreenCount: 1

    readonly property bool isDesktop: UPower.displayDevice.ready ? !UPower.displayDevice.isLaptopBattery : SystemInfo.isDesktop
    readonly property int batCap: UPower.displayDevice.ready ? Math.round(UPower.displayDevice.percentage * 100) : 0
    readonly property string batPercent: batCap + "%"
    readonly property string batStatus: UPower.displayDevice.ready ? (UPower.displayDevice.state === UPowerDeviceState.FullyCharged ? "Full" : (UPower.displayDevice.state === UPowerDeviceState.Charging ? "Charging" : "Unknown")) : "Unknown"
    readonly property bool isCharging: UPower.displayDevice.ready && (UPower.displayDevice.state === UPowerDeviceState.Charging || UPowerDeviceState.FullyCharged)
    readonly property string batIcon: isCharging ? "󰂄" : (batCap > 20 ? "󰁹" : "󰂃")

    readonly property color batDynamicColor: {
        if (batCap <= 15 && !isCharging) return ThemeBackend.red;
        if (batCap <= 25 && !isCharging) return ThemeBackend.peach;
        if (isCharging) return ThemeBackend.green;
        return ThemeBackend.text;
    }

    function updateDeInfo() {
        let de = SystemInfo.desktopEnv ? SystemInfo.desktopEnv.toLowerCase() : "";
        root.isNiri = de.indexOf("niri") !== -1;
        root.isSway = de.indexOf("sway") !== -1;
    }

    function updateScreenCount() {
        root.connectedScreenCount = Quickshell.screens ? Quickshell.screens.length : 1;
    }

    Component.onCompleted: {
        SystemInfo.fetch();
        root.updateDeInfo();
        root.updateScreenCount();
    }

    Connections {
        target: Quickshell
        function onScreensChanged() {
            root.updateScreenCount();
        }
    }

    function switchKbLayout() {
        root.updateDeInfo();
        if (root.isNiri) {
            Quickshell.execDetached(["niri", "msg", "action", "switch-layout", "next"]);
        } else if (root.isSway) {
            Quickshell.execDetached(["swaymsg", "input", "type:keyboard", "xkb_switch_layout", "next"]);
        } else {
            Quickshell.execDetached(["hyprctl", "switchxkblayout", "main", "next"]);
        }
    }

    Timer {
        id: kbPollerRestartTimer
        interval: 400
        repeat: false
        onTriggered: {
            kbWaiter.running = false;
            kbPoller.running = false;
            if (rootLock.locked) kbPoller.running = true;
        }
    }

    Process {
        id: kbPoller
        running: rootLock.locked
        command: [
            "bash",
            "-c",
            root.isNiri
                ? "layout=$(niri msg -j keyboard-layouts 2>/dev/null | jq -r '.names[.current_idx] // empty' | head -n1); [[ -z \"$layout\" || \"$layout\" == \"null\" ]] && layout=\"US\"; echo \"${layout:0:2}\" | tr '[:lower:]' '[:upper:]'"
                : (root.isSway
                    ? "layout=$(swaymsg -t get_inputs 2>/dev/null | jq -r '[.[] | select(.type == \"keyboard\" and .xkb_active_layout_name != null)] | .[0].xkb_active_layout_name // empty' | head -n1); [[ -z \"$layout\" || \"$layout\" == \"null\" ]] && layout=\"US\"; echo \"${layout:0:2}\" | tr '[:lower:]' '[:upper:]'"
                    : "layout=$(LC_ALL=C hyprctl devices -j 2>/dev/null | jq -r '(.keyboards[] | select(.main == true) | .active_keymap) // .keyboards[0].active_keymap // empty' | head -n1); [[ -z \"$layout\" || \"$layout\" == \"null\" ]] && layout=\"US\"; echo \"${layout:0:2}\" | tr '[:lower:]' '[:upper:]'")
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "" && root.kbLayout !== txt) root.kbLayout = txt;
                kbWaiter.running = false;
                if (rootLock.locked) kbWaiter.running = true;
            }
        }
    }

    Process {
        id: kbWaiter
        command: [
            "bash",
            Caching.qsDir + "/watchers/kb_wait.sh",
            root.isNiri ? "niri" : (root.isSway ? "sway" : "hyprland")
        ]
        onExited: {
            kbPoller.running = false;
            if (rootLock.locked) kbPoller.running = true;
        }
    }

    Process {
        id: grimLockSnapProcess
        property string timeStamp: ""
        property var screenNames: []

        command: {
            let ts = timeStamp;
            let dir = Caching.getRunDir("screenshot");
            let cmd = "dir=\"" + dir + "\"; mkdir -p \"$dir\"; ";
            let mons = screenNames;
            if (mons && mons.length > 0) {
                for (let i = 0; i < mons.length; i++) {
                    let m = mons[i];
                    cmd += "grim -o \"" + m + "\" -l 0 \"$dir/lock_freeze_" + m + "_" + ts + ".png\" & ";
                }
                cmd += "wait; ";
                let firstMon = mons[0];
                cmd += "ln -sf \"$dir/lock_freeze_" + firstMon + "_" + ts + ".png\" \"$dir/lock_freeze_default_" + ts + ".png\" 2>/dev/null || cp -f \"$dir/lock_freeze_" + firstMon + "_" + ts + ".png\" \"$dir/lock_freeze_default_" + ts + ".png\" 2>/dev/null || true;";
            } else {
                cmd += "grim -l 0 \"$dir/lock_freeze_default_" + ts + ".png\" || exit 1;";
            }
            return ["bash", "-c", cmd];
        }

        onExited: (exitCode) => {
            grimTimeoutTimer.stop();
            if (exitCode === 0) {
                root.freezeTimestamp = timeStamp;
            } else {
                root.freezeTimestamp = "";
            }
            root.doLock();
        }
    }

    Timer {
        id: grimTimeoutTimer
        interval: 500
        repeat: false
        onTriggered: {
            grimLockSnapProcess.running = false;
            root.doLock();
        }
    }

    // Settings → Trợ năng → "Giảm chuyển động" turns Hyprland animations off: the lock screen then skips
    // the vault gate. Probed at start and on each lock, before the surface appears.
    property bool calmMotion: false
    Process {
        id: motionProbe
        running: true
        command: ["hyprctl", "getoption", "animations:enabled", "-j"]
        stdout: StdioCollector { onStreamFinished: { try { root.calmMotion = JSON.parse(this.text).bool === false; } catch (e) {} } }
    }

    function lock() {
        if (rootLock.locked) return;
        motionProbe.running = false;
        motionProbe.running = true;
        let ts = Date.now().toString();
        let mons = [];
        if (Quickshell.screens) {
            for (let i = 0; i < Quickshell.screens.length; i++) {
                if (Quickshell.screens[i] && Quickshell.screens[i].name) {
                    mons.push(Quickshell.screens[i].name);
                }
            }
        }
        grimLockSnapProcess.screenNames = mons;
        grimLockSnapProcess.timeStamp = ts;
        grimLockSnapProcess.running = false;
        grimLockSnapProcess.running = true;
        grimTimeoutTimer.restart();
    }

    function doLock() {
        grimTimeoutTimer.stop();
        SystemInfo.fetch();
        root.updateDeInfo();
        root.updateScreenCount();
        root.isUnlocking = false;
        lockUI.failed = false;
        lockUI.authenticating = false;
        lockUI.fpFailed = false;
        lockUI.statusText = I18n.t("lock.status.locked");
        rootLock.locked = true;
        Wallpaper.setPlayback("all", "pause");
        pamActionTimer.start();
        fpProbe.running = false;
        fpProbe.running = true;
        kbPollerRestartTimer.restart();
    }

    function finishUnlock() {
        if (root.isUnlocking) return;
        root.isUnlocking = true;
        // whichever of password / fingerprint won, stop the other one
        fpRetryTimer.stop();
        if (fpPam.active) fpPam.abort();
        if (pam.active) pam.abort();
    }

    function completeUnlock() {
        if (!rootLock.locked) return;
        rootLock.locked = false;
        Wallpaper.setPlayback("all", "play");
        root.isUnlocking = false;
        kbWaiter.running = false;
        kbPoller.running = false;
        fpRetryTimer.stop();
        if (fpPam.active) fpPam.abort();
        if (root.freezeTimestamp !== "") {
            Quickshell.execDetached(["bash", "-c", "rm -f " + Caching.getRunDir("screenshot") + "/lock_freeze_*_" + root.freezeTimestamp + ".png"]);
            root.freezeTimestamp = "";
        }
    }

    IpcHandler {
        target: "lock"
        function activate(): void {
            root.lock();
        }
    }

    Settings {
        id: lockSettings
        category: "LockScreen"
        property bool hidePassword: false
        property int revealDuration: 300
    }

    QtObject {
        id: lockUI
        property bool failed: false
        property bool authenticating: false
        property bool fpFailed: false
        property string statusText: I18n.t("lock.status.locked")
    }

    Timer {
        id: pamActionTimer
        interval: 350
        onTriggered: {
            if (rootLock.locked) {
                pam.start();
            }
        }
    }

    readonly property var pamContext: pam
    readonly property var lockState: lockUI

    PamContext {
        id: pam

        onCompleted: (result) => {
            lockUI.authenticating = false;
            if (root.isUnlocking) return;   // aborted after a fingerprint unlock
            if (result === PamResult.Success) {
                root.finishUnlock();
            } else {
                lockUI.failed = true;
                lockUI.statusText = I18n.t("lock.status.access_denied");
                pamActionTimer.start();
            }
        }
    }

    // Fingerprint: its own PAM session (lock/pam/fingerprint, pam_fprintd only) running next to the
    // password one, so typing a password never waits for the reader to time out. No /etc/pam.d change needed.
    property bool hasFingerprint: false

    Process {
        id: fpProbe
        command: ["bash", "-c", "command -v fprintd-list >/dev/null && fprintd-list \"$USER\" 2>/dev/null | grep -q ' - #' && echo yes"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.hasFingerprint = this.text.trim() === "yes";
                root.startFingerprint();
            }
        }
    }

    function startFingerprint() {
        if (rootLock.locked && root.hasFingerprint && !root.isUnlocking && !fpPam.active) fpPam.start();
    }

    Timer {
        id: fpRetryTimer
        interval: 1500
        onTriggered: root.startFingerprint()
    }

    Timer {
        id: fpFailedReset
        interval: 2500
        onTriggered: lockUI.fpFailed = false
    }

    PamContext {
        id: fpPam
        configDirectory: Caching.qsDir + "/lock/pam"
        config: "fingerprint"

        // pam_fprintd reports a wrong finger as an error message and keeps listening
        onPamMessage: {
            if (messageIsError) {
                lockUI.fpFailed = true;
                fpFailedReset.restart();
            }
        }
        onCompleted: (result) => {
            if (root.isUnlocking) return;
            if (result === PamResult.Success) {
                root.finishUnlock();
            } else {
                fpRetryTimer.interval = 1500;
                fpRetryTimer.restart();
            }
        }
        // reader busy or fprintd gone: back off instead of spinning
        onError: (error) => {
            fpRetryTimer.interval = 5000;
            fpRetryTimer.restart();
        }
    }

    Process {
        id: suspendProcess
        command: ["bash", Caching.zoneCDir + "/scripts/system/suspend.sh"]
        onExited: {
            SystemInfo.fetch();
            root.updateDeInfo();
            pamActionTimer.restart();
            kbPollerRestartTimer.restart();
            if (rootLock.locked) {
                pam.start();
            }
            // the reader resets across suspend: start a fresh fingerprint session
            if (fpPam.active) fpPam.abort();
            fpRetryTimer.interval = 1500;
            fpRetryTimer.restart();
        }
    }

    Process {
        id: poweroffProcess
        command: ["bash", Caching.zoneCDir + "/scripts/system/poweroff.sh"]
    }

    Process {
        id: reloadProcess
        command: ["bash", Caching.zoneCDir + "/scripts/system/reboot.sh"]
    }

    WlSessionLock {
        id: rootLock
        locked: false

        surface: Component {
            WlSessionLockSurface {
                id: surface
                // transparent only while the vault gate runs, so the desktop shows around the
                // moving halves (Hyprland misc:session_lock_xray); opaque otherwise
                color: root.isUnlocking || frostLock.gateActive ? "transparent" : "black"

                // Frost design surface (FrostLockScreen.qml); this file keeps the lock and PAM.
                FrostLockScreen {
                    id: frostLock
                    anchors.fill: parent
                    focus: true
                    lockRoot: root
                    // through root: inside FrostLockScreen the names `pam` / `lockUI` are its own (empty) properties
                    pam: root.pamContext
                    lockUI: root.lockState
                    screen: surface.screen
                    powerActions: ({ sleep: () => suspendProcess.running = true, reboot: () => reloadProcess.running = true, poweroff: () => poweroffProcess.running = true })
                }
                UnlockFx {
                    anchors.fill: parent
                    lock: frostLock
                }
            }
        }
    }
}
