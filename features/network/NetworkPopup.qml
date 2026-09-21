import QtQuick
import qs.core.popup
import qs.core.services
import qs.core.state
import qs.core.theme
import qs.core.ui
import qs.features.network

// Wi-Fi and Bluetooth radar. Connected networks/devices are glowing cores; nearby ones
// orbit as cards (hold to connect). "Current Device" swaps the orbit for live details
// linked to their core by energy strands. Tab switches between Wi-Fi and Bluetooth.
PopupBase {
    id: root

    property string mode: "wifi"
    property bool showInfo: true

    readonly property bool isWifi: mode === "wifi"
    readonly property color wifiAccent: Qt.lighter(Colours.sapphire, 1.15)
    readonly property color btAccent: Colours.mauve
    readonly property color accent: isWifi ? wifiAccent : btAccent

    readonly property bool powered: isWifi ? NetworkService.wifiEnabled : Bluetooth.enabled
    readonly property var cores: {
        if (!powered)
            return [];
        if (isWifi)
            return NetworkService.kind === "wifi" ? [{ id: NetworkService.ssid, name: NetworkService.ssid, icon: NetworkService.wifiIcon(NetworkService.strength) }] : [];
        return Bluetooth.connected.slice(0, 5).map(d => ({ id: d.address, name: d.name || d.address, icon: String.fromCodePoint(0xF00B1), device: d }));
    }
    readonly property bool connected: cores.length > 0
    readonly property bool multi: !isWifi && cores.length > 1
    property real multiShift: multi ? 1 : 0

    Behavior on multiShift {
        NumberAnimation {
            duration: 1200
            easing.type: Easing.InOutExpo
        }
    }

    blobPrimary: connected ? accent : Colours.surface2
    blobSecondary: connected ? Qt.darker(accent, 1.25) : Colours.surface1
    blobPrimaryOpacity: powered ? 0.08 : 0.02
    blobSecondaryOpacity: powered ? 0.06 : 0.01

    focus: true
    Keys.onTabPressed: mode = isWifi ? "bt" : "wifi"

    onArgChanged: {
        if (arg === "wifi" || arg === "bt")
            mode = arg;
    }
    onConnectedChanged: showInfo = connected
    onModeChanged: {
        showInfo = connected;
        Bluetooth.setDiscovering(!isWifi);
        if (isWifi)
            NetworkService.rescan();
    }
    Component.onCompleted: {
        if (arg === "wifi" || arg === "bt")
            mode = arg;
        showInfo = connected;
        syncCards();
        if (isWifi)
            NetworkService.rescan();
        else
            Bluetooth.setDiscovering(true);
    }
    Component.onDestruction: Bluetooth.setDiscovering(false)

    // Card nodes: { key, name, icon, action, info, actionable, highlight, owner }.
    // `owner` is the index of the core an info card belongs to, or -1.
    readonly property var deviceNodes: {
        const list = [];
        if (isWifi) {
            const others = NetworkService.networks.filter(n => !n.active);
            const strongest = others.reduce((best, n) => !best || n.signal > best.signal ? n : best, null);
            for (const n of others)
                list.push(node(n.ssid, n.ssid, NetworkService.wifiIcon(n.signal), "Connect", false, !connected && n === strongest));
        } else {
            for (const d of Bluetooth.nearby)
                list.push(node(d.address, d.name || d.address, String.fromCodePoint(0xF00AF), d.paired ? "Connect" : "Pair", false, d.paired));
        }
        if (connected)
            list.push(node("action_info", "Current Device", String.fromCodePoint(0xF0493), "View Info", true, true, -1, true));
        return list;
    }

    readonly property var infoNodes: {
        const list = [];
        if (isWifi) {
            list.push(node("signal", NetworkService.strength + "%", NetworkService.wifiIcon(NetworkService.strength), "Signal Strength", true, false, 0));
            list.push(node("security", NetworkService.security || "Open", String.fromCodePoint(0xF099D), "Security", true, false, 0));
            if (NetworkService.ip)
                list.push(node("ip", NetworkService.ip, String.fromCodePoint(0xF0A5F), "IP Address", true, false, 0));
            if (NetworkService.freq)
                list.push(node("freq", NetworkService.freq, String.fromCodePoint(0xF05A9), "Band", true, false, 0));
        } else {
            cores.forEach((core, i) => {
                const battery = Bluetooth.battery(core.device);
                if (battery >= 0)
                    list.push(node("bat_" + core.id, battery + "%", String.fromCodePoint(0xF0949), "Battery", true, false, i));
                list.push(node("mac_" + core.id, core.id, String.fromCodePoint(0xF048B), "MAC Address", true, false, i));
            });
        }
        list.push(node("action_scan", "Scan Devices", String.fromCodePoint(0xF0349), "Switch View", true, true, -1, true));
        return list;
    }

    readonly property var cards: showInfo && connected ? infoNodes : deviceNodes

    onCardsChanged: syncCards()

    function node(key, name, icon, action, info, actionable, owner, highlight) {
        return { key: key, name: name, icon: icon, action: action, info: info, actionable: actionable, owner: owner ?? -1, highlight: highlight ?? actionable };
    }

    // Updates cardModel in place by key, so polls don't recreate (and re-animate) cards.
    function syncCards() {
        const keys = cards.map(c => c.key);
        for (let i = cardModel.count - 1; i >= 0; i--) {
            if (!keys.includes(cardModel.get(i).key))
                cardModel.remove(i);
        }
        cards.forEach((card, i) => {
            let at = -1;
            for (let j = i; j < cardModel.count; j++) {
                if (cardModel.get(j).key === card.key) {
                    at = j;
                    break;
                }
            }
            if (at < 0) {
                cardModel.insert(i, card);
                return;
            }
            if (at !== i)
                cardModel.move(at, i, 1);
            for (const role in card) {
                if (cardModel.get(i)[role] !== card[role])
                    cardModel.setProperty(i, role, card[role]);
            }
        });
    }

    function trigger(card) {
        if (card.key === "action_info" || card.key === "action_scan") {
            showInfo = !showInfo;
        } else if (!card.info) {
            if (isWifi)
                NetworkService.connectTo(card.key);
            else
                Bluetooth.connect(Bluetooth.devices.find(d => d.address === card.key));
        }
    }

    ListModel {
        id: cardModel
    }

    function togglePower() {
        if (isWifi)
            NetworkService.toggleWifi();
        else
            Bluetooth.toggle();
    }

    Item {
        id: stage

        anchors.fill: parent
        anchors.bottomMargin: UiScale.s(80)

        readonly property real cx: width / 2
        readonly property real cy: height / 2
        // v1 turns the swarm once every ~130 s.
        readonly property real spin: root.orbitAngle * 0.675

        Repeater {
            model: 3

            Rectangle {
                required property int index

                anchors.centerIn: parent
                width: UiScale.s(280) + index * UiScale.s(170)
                height: width
                radius: width / 2
                color: "transparent"
                border.color: root.accent
                border.width: 1
                opacity: !root.powered ? 0 : (root.connected ? 0.08 - index * 0.02 : 0.03)

                Behavior on opacity {
                    NumberAnimation { duration: 600 }
                }
            }
        }

        NodeLinks {
            anchors.fill: parent
            accent: root.accent
            active: root.powered && root.connected && root.showInfo
            links: {
                const list = [];
                for (let i = 0; i < cardRepeater.count; i++) {
                    const card = cardRepeater.itemAt(i);
                    if (!card || !card.node.info || card.node.actionable)
                        continue;
                    const core = coreRepeater.itemAt(Math.max(0, card.node.owner));
                    list.push({ from: core, to: card });
                }
                return list;
            }
        }

        Repeater {
            id: coreRepeater

            // Always at least one core, so the offline state has something to show.
            model: Math.max(1, root.cores.length)

            delegate: RadioCore {
                required property int index

                readonly property real angle: stage.spin + index / Math.max(1, root.cores.length) * Math.PI * 2
                readonly property real size: root.powered ? UiScale.s(200) - UiScale.s(30) * root.multiShift - UiScale.s(15) * Math.max(0, root.cores.length - 2) : UiScale.s(160)

                width: size
                height: size
                x: stage.cx - width / 2 + Math.cos(angle) * (UiScale.s(180) + (root.cores.length > 2 ? UiScale.s(20) : 0)) * root.multiShift
                y: stage.cy - height / 2 + Math.sin(angle) * (UiScale.s(110) + (root.cores.length > 2 ? UiScale.s(15) : 0)) * root.multiShift
                z: 1
                accent: root.accent
                powered: root.powered
                mode: root.mode
                device: root.cores[index] ?? null
                crowd: root.multiShift
                onDisconnectRequested: device => {
                    if (root.isWifi)
                        NetworkService.disconnectWifi();
                    else
                        Bluetooth.disconnect(device.device);
                }

                Behavior on width {
                    NumberAnimation {
                        duration: 600
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        Repeater {
            id: cardRepeater

            model: cardModel

            delegate: OrbitCard {
                id: card

                required property int index
                required property string key
                required property string name
                required property string icon
                required property string action
                required property bool info
                required property bool actionable
                required property bool highlight
                required property int owner

                property real entry: 0
                readonly property int count: cardModel.count
                readonly property var parentCore: owner >= 0 ? coreRepeater.itemAt(owner) : null
                readonly property var siblings: root.cards.filter(c => c.owner === owner)
                readonly property int localIndex: siblings.findIndex(c => c.key === key)
                readonly property real crowdScale: count > 10 ? Math.max(0.6, 12 / count) : (root.multiShift > 0.5 ? (root.cores.length > 2 ? 0.7 : 0.8) : 1)

                readonly property real singleAngle: stage.spin + index / Math.max(1, count) * Math.PI * 2
                readonly property real ring: info ? 0 : (index % 2) * UiScale.s(40)
                readonly property real parentAngle: parentCore ? parentCore.angle : 0
                readonly property real spread: siblings.length > 1 ? (localIndex / (siblings.length - 1) - 0.5) * Math.PI * 0.8 : 0
                readonly property bool attached: root.multiShift > 0.5 && info && owner >= 0
                readonly property real angle: attached ? parentAngle + spread : singleAngle
                readonly property real radiusX: attached ? UiScale.s(root.cores.length > 2 ? 180 : 160) : (info ? (actionable && root.multiShift > 0.5 ? 0 : UiScale.s(280)) : UiScale.s(320) + ring)
                readonly property real radiusY: attached ? UiScale.s(root.cores.length > 2 ? 180 : 160) : (info ? (actionable && root.multiShift > 0.5 ? 0 : UiScale.s(180)) : UiScale.s(200) + ring)
                readonly property real originX: attached ? parentCore.x + parentCore.width / 2 : stage.cx
                readonly property real originY: attached ? parentCore.y + parentCore.height / 2 : stage.cy
                readonly property real bob: info && !attached ? Math.sin(root.orbitAngle * 6) * UiScale.s(12) : 0

                node: ({
                        key: key,
                        name: name,
                        icon: icon,
                        action: action,
                        info: info,
                        actionable: actionable,
                        highlight: highlight,
                        owner: owner
                    })
                accent: root.accent
                busy: root.isWifi && !!NetworkService.connecting[key]
                x: originX - width / 2 + Math.cos(angle) * radiusX * (0.25 + 0.75 * entry)
                y: originY - height / 2 + Math.sin(angle) * radiusY * (0.25 + 0.75 * entry) + bob
                z: engaged ? 10 : 2
                opacity: entry
                scale: crowdScale * (engaged ? 1.08 : 1) * entry
                visible: root.powered
                onTriggered: node => root.trigger(node)

                Behavior on entry {
                    NumberAnimation {
                        duration: 600
                        easing.type: Easing.OutBack
                    }
                }

                Timer {
                    running: true
                    interval: 40 + card.index * 30
                    onTriggered: card.entry = 1
                }
            }
        }
    }

    ModeDock {
        anchors.fill: parent
        mode: root.mode
        wifiAccent: root.wifiAccent
        btAccent: root.btAccent
        powered: root.powered
        onModeSelected: mode => root.mode = mode
        onPowerToggled: root.togglePower()
    }
}
