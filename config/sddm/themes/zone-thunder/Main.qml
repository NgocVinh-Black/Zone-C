import QtQuick
import QtQuick.Window
import QtMultimedia
import Qt5Compat.GraphicalEffects
import SddmComponents 2.0

// Zone Thunder — based on the material-you theme by Darkkal44 (MIT)
Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    color: c.crust

    // Bang mau + hinh nen theo theme dang dung cua Zone-C.
    // Shell ghi current/theme.conf (thu muc current/ thuoc user) moi khi doi theme/hinh nen;
    // chua co file thi dung mau Zone Thunder mac dinh ben duoi.
    // SDDM doc current/theme.conf (ConfigFile trong metadata.desktop) vao doi tuong "config"
    property var live: (typeof config !== "undefined" && config) ? config : ({})
    function pick(key, fallback) {
        let v = root.live[key];
        return (v !== undefined && v !== null && String(v) !== "") ? String(v) : fallback;
    }

    QtObject {
        id: c
        readonly property color crust: root.pick("crust", "#030817")
        readonly property color mantle: root.pick("mantle", "#06102a")
        readonly property color base: root.pick("base", "#0a1633")
        readonly property color surface0: root.pick("surface0", "#112552")
        readonly property color surface1: root.pick("surface1", "#183368")
        readonly property color surface2: root.pick("surface2", "#22448a")
        readonly property color subtext0: root.pick("subtext0", "#8199cc")
        readonly property color subtext1: root.pick("subtext1", "#b7c9ee")
        readonly property color text: root.pick("text", "#e6efff")
        readonly property color blue: root.pick("blue", "#3d9bff")
        readonly property color sapphire: root.pick("sapphire", "#5cc0ff")
        readonly property color teal: root.pick("teal", "#62e3ff")
        readonly property color mauve: root.pick("mauve", "#86b4ff")
        readonly property color red: root.pick("red", "#ff5a74")
        readonly property color glass: Qt.rgba(base.r, base.g, base.b, 0.72)   // base @ 72%
        readonly property color edge: root.pick("edge", "#2b4f94")
        readonly property color glow: Qt.rgba(blue.r, blue.g, blue.b, 0.55)    // blue @ 55%
    }

    // ---------- background: still frame under a looping video ----------
    Image {
        anchors.fill: parent
        source: root.pick("background", "") !== "" ? Qt.resolvedUrl("current/" + root.pick("background", "")) : "bg.png"
        fillMode: Image.PreserveAspectCrop
    }

    Video {
        anchors.fill: parent
        // Theme co hinh nen video (Thunder) -> phat video; hinh nen anh (Crystal, Frost) -> khong co video
        visible: source != ""
        source: root.pick("background", "") !== ""
            ? (root.pick("video", "") !== "" ? Qt.resolvedUrl("current/" + root.pick("video", "")) : "")
            : Qt.resolvedUrl("bg.mp4")
        fillMode: VideoOutput.PreserveAspectCrop
        loops: MediaPlayer.Infinite
        muted: true
        autoPlay: true
    }

    RadialGradient {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0.012, 0.03, 0.09, 0.33) }
            GradientStop { position: 0.75; color: Qt.rgba(0.012, 0.03, 0.09, 0.67) }
        }
    }

    readonly property real s: Screen.height / 768
    property bool isQuickshell: typeof sddm === "undefined" || sddm.hostName === undefined
    property int sessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex: (typeof userModel !== "undefined" && userModel.lastIndex >= 0) ? userModel.lastIndex : 0

    property real ui1: 0
    property string errorMessage: ""

    FontLoader {
        id: customFont
        source: "font/GoogleSans-VariableFont_GRAD,opsz,wght.ttf"
    }

    readonly property string sansFont: customFont.name !== "" ? customFont.name : "Roboto, Inter, sans-serif"

    function syncModel() {
        let str = pwd.text;
        let minLen = Math.min(str.length, charModel.count);
        let matchLen = 0;
        while (matchLen < minLen && str[matchLen] === charModel.get(matchLen).char) {
            matchLen++;
        }
        while (charModel.count > matchLen) {
            charModel.remove(charModel.count - 1);
        }
        for (let i = matchLen; i < str.length; i++) {
            charModel.append({ char: str[i] });
        }
    }

    ListView {
        id: sessionHelper
        model: typeof sessionModel !== "undefined" ? sessionModel : null
        currentIndex: root.sessionIndex
        opacity: 0
        width: 100
        height: 100
        z: -100
        delegate: Item {
            property string sName: model.name || ""
        }
    }

    ListView {
        id: userHelper
        model: typeof userModel !== "undefined" ? userModel : null
        currentIndex: root.userIndex
        opacity: 0
        width: 100
        height: 100
        z: -100
        delegate: Item {
            property string uName: model.realName || model.name || ""
            property string uLogin: model.name || ""
        }
    }

    Timer {
        id: focusTimer
        interval: 300
        running: true
        onTriggered: pwd.forceActiveFocus()
    }

    Connections {
        target: typeof sddm !== "undefined" ? sddm : null
        function onLoginFailed() {
            root.errorMessage = "ACCESS DENIED";
            pwd.text = "";
            charModel.clear();
            shakeAnim.start();
            errTimer.start();
        }
    }

    Timer {
        id: errTimer
        interval: 3000
        onTriggered: root.errorMessage = ""
    }

    Component.onCompleted: {
        fadeAnim.start();
        if (typeof keyboard !== "undefined") keyboard.numLock = true;
    }

    SequentialAnimation {
        id: fadeAnim
        PauseAnimation { duration: 500 }
        NumberAnimation { target: root; property: "ui1"; from: 0; to: 1; duration: 900; easing.type: Easing.OutCubic }
    }

    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: shakeTranslate; property: "x"; to: 15*s; duration: 50 }
        NumberAnimation { target: shakeTranslate; property: "x"; to: -15*s; duration: 50 }
        NumberAnimation { target: shakeTranslate; property: "x"; to: 15*s; duration: 50 }
        NumberAnimation { target: shakeTranslate; property: "x"; to: -15*s; duration: 50 }
        NumberAnimation { target: shakeTranslate; property: "x"; to: 0; duration: 50 }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        z: -1
        onClicked: pwd.forceActiveFocus()
    }

    // ---------- quick settings tile ----------
    component QuickTile: Rectangle {
        id: tile
        property string title
        property string subtitle
        property string iconSvg
        signal activated()

        width: 180 * root.s; height: 76 * root.s; radius: 38 * root.s
        color: tileMouse.pressed ? c.surface2 : (tileMouse.containsMouse ? c.blue : c.glass)
        border.width: 1
        border.color: tileMouse.containsMouse ? c.sapphire : c.edge
        scale: tileMouse.pressed ? 0.95 : (tileMouse.containsMouse ? 1.03 : 1.0)
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

        layer.enabled: tileMouse.containsMouse
        layer.effect: Glow { radius: 14; samples: 29; color: c.glow; spread: 0.1 }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 16 * root.s
            anchors.rightMargin: 16 * root.s
            spacing: 12 * root.s

            Rectangle {
                width: 48 * root.s; height: 48 * root.s; radius: 24 * root.s
                color: tileMouse.containsMouse ? c.crust : c.surface0
                border.width: tileMouse.containsMouse ? 0 : 1
                border.color: c.surface2
                anchors.verticalCenter: parent.verticalCenter
                Behavior on color { ColorAnimation { duration: 150 } }

                Image {
                    id: tileIcon
                    source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='black' stroke-width='2.5' stroke-linecap='round' stroke-linejoin='round'>" + tile.iconSvg + "</svg>"
                    anchors.centerIn: parent
                    width: 20 * root.s
                    height: 20 * root.s
                    sourceSize.width: 40 * root.s
                    sourceSize.height: 40 * root.s
                    visible: false
                }
                ColorOverlay {
                    anchors.fill: tileIcon
                    source: tileIcon
                    color: tileMouse.containsMouse ? c.teal : c.mauve
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2 * root.s

                Text {
                    text: tile.title
                    font.family: root.sansFont
                    font.pixelSize: 12 * root.s
                    font.bold: true
                    color: tileMouse.containsMouse ? c.crust : c.text
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                Text {
                    text: tile.subtitle
                    font.family: root.sansFont
                    font.pixelSize: 9 * root.s
                    color: tileMouse.containsMouse ? c.base : c.subtext0
                    Behavior on color { ColorAnimation { duration: 150 } }
                    elide: Text.ElideRight
                    width: 90 * root.s
                }
            }
        }

        MouseArea {
            id: tileMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.activated()
        }
    }

    Row {
        id: mainLayout
        anchors.centerIn: parent
        spacing: 96 * s
        opacity: root.ui1
        scale: 0.96 + (0.04 * root.ui1)
        transform: Translate { y: (1 - root.ui1) * 30 * s }

        // ---------- clock ----------
        Column {
            spacing: 24 * s
            anchors.verticalCenter: parent.verticalCenter

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: {
                    let d = new Date();
                    hText.text = Qt.formatTime(d, "hh");
                    mText.text = Qt.formatTime(d, "mm");
                    dateChipText.text = Qt.formatDate(d, "dddd, MMM d").toUpperCase();
                }
            }

            Column {
                spacing: -24 * s

                Text {
                    id: hText
                    text: Qt.formatTime(new Date(), "hh")
                    font.family: root.sansFont
                    font.pixelSize: 140 * s
                    font.weight: Font.Bold
                    color: c.text
                    layer.enabled: true
                    layer.effect: Glow { radius: 24; samples: 49; color: c.glow; spread: 0.05 }
                }

                Text {
                    id: mText
                    text: Qt.formatTime(new Date(), "mm")
                    font.family: root.sansFont
                    font.pixelSize: 140 * s
                    font.weight: Font.Bold
                    color: c.blue
                    layer.enabled: true
                    layer.effect: Glow { radius: 30; samples: 61; color: c.glow; spread: 0.1 }
                }
            }

            Rectangle {
                width: dateChipText.implicitWidth + 32 * s
                height: 44 * s
                radius: 22 * s
                color: c.glass
                border.width: 1
                border.color: c.edge

                Text {
                    id: dateChipText
                    anchors.centerIn: parent
                    text: Qt.formatDate(new Date(), "dddd, MMM d").toUpperCase()
                    font.family: root.sansFont
                    font.pixelSize: 11 * s
                    font.bold: true
                    font.letterSpacing: 1 * s
                    color: c.mauve
                }
            }
        }

        // ---------- quick settings + login ----------
        Column {
            spacing: 24 * s
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: "QUICK SETTINGS"
                font.family: root.sansFont
                font.pixelSize: 11 * s
                font.bold: true
                font.letterSpacing: 1.5 * s
                color: c.subtext0
            }

            Grid {
                columns: 2
                spacing: 16 * s

                QuickTile {
                    title: "POWER"
                    subtitle: "SHUT DOWN"
                    iconSvg: "<path d='M18.36 6.64a9 9 0 1 1-12.73 0'></path><line x1='12' y1='2' x2='12' y2='12'></line>"
                    onActivated: if (!root.isQuickshell) sddm.powerOff();
                }

                QuickTile {
                    title: "SESSION"
                    subtitle: ((sessionHelper.currentItem && sessionHelper.currentItem.sName) ? sessionHelper.currentItem.sName : "HYPRLAND").toUpperCase()
                    iconSvg: "<circle cx='12' cy='12' r='3'></circle><path d='M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z'></path>"
                    onActivated: {
                        if (!root.isQuickshell && typeof sessionModel !== "undefined" && sessionModel.rowCount() > 0) {
                            root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount();
                        }
                    }
                }

                QuickTile {
                    title: "REBOOT"
                    subtitle: "RESTART"
                    iconSvg: "<polyline points='23 4 23 10 17 10'></polyline><path d='M20.49 15a9 9 0 1 1-2.12-9.36L23 10'></path>"
                    onActivated: if (!root.isQuickshell) sddm.reboot();
                }

                QuickTile {
                    title: "SLEEP"
                    subtitle: "SUSPEND"
                    iconSvg: "<path d='M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z'></path>"
                    onActivated: if (!root.isQuickshell) sddm.suspend();
                }
            }

            Rectangle {
                id: loginCard
                width: 376 * s
                height: 180 * s
                radius: 32 * s
                color: c.glass
                border.width: 1
                border.color: c.edge
                transform: Translate { id: shakeTranslate }

                Column {
                    anchors.fill: parent
                    anchors.margins: 20 * s
                    spacing: 12 * s

                    Row {
                        width: parent.width
                        spacing: 8 * s

                        Item {
                            width: 12 * s
                            height: 12 * s
                            anchors.verticalCenter: parent.verticalCenter
                            Image {
                                id: lockIcon
                                source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='black' stroke-width='2.5' stroke-linecap='round' stroke-linejoin='round'><rect x='3' y='11' width='18' height='11' rx='2' ry='2'></rect><path d='M7 11V7a5 5 0 0 1 10 0v4'></path></svg>"
                                anchors.fill: parent
                                sourceSize.width: 24 * s
                                sourceSize.height: 24 * s
                                visible: false
                            }
                            ColorOverlay {
                                anchors.fill: lockIcon
                                source: lockIcon
                                color: c.blue
                            }
                        }
                        Text {
                            text: "ZONE-C"
                            font.family: root.sansFont
                            font.pixelSize: 10 * s
                            font.bold: true
                            font.letterSpacing: 1 * s
                            color: c.subtext0
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "•  now"
                            font.family: root.sansFont
                            font.pixelSize: 10 * s
                            color: c.subtext0
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 52 * s
                        radius: 26 * s
                        color: c.mantle
                        border.color: root.errorMessage !== "" ? c.red : (pwd.activeFocus ? c.blue : c.surface0)
                        border.width: 2 * s
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        ListModel {
                            id: charModel
                        }

                        ListView {
                            id: charRow
                            anchors.centerIn: parent
                            height: 12 * s
                            orientation: ListView.Horizontal
                            interactive: false
                            boundsBehavior: Flickable.StopAtBounds
                            spacing: 6 * s
                            width: contentWidth
                            model: charModel

                            add: Transition {
                                ParallelAnimation {
                                    NumberAnimation { property: "scale"; from: 0.60; to: 1.0; duration: 240; easing.type: Easing.OutBack; easing.overshoot: 1.35 }
                                    NumberAnimation { property: "y"; from: 3.5 * s; to: 0; duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.25 }
                                    NumberAnimation { property: "rotation"; from: -9; to: 0; duration: 220; easing.type: Easing.OutCubic }
                                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150; easing.type: Easing.OutQuad }
                                }
                            }

                            remove: Transition {
                                ParallelAnimation {
                                    NumberAnimation { property: "scale"; to: 0.0; duration: 130; easing.type: Easing.InCubic }
                                    NumberAnimation { property: "y"; to: 2 * s; duration: 130; easing.type: Easing.InCubic }
                                    NumberAnimation { property: "rotation"; to: 6; duration: 130; easing.type: Easing.InCubic }
                                    NumberAnimation { property: "opacity"; to: 0; duration: 100; easing.type: Easing.InQuad }
                                }
                            }

                            displaced: Transition {
                                NumberAnimation { properties: "x,y"; duration: 160; easing.type: Easing.OutCubic }
                            }

                            delegate: Item {
                                id: charSlot
                                required property int index
                                required property string char

                                width: 12 * s
                                height: 12 * s
                                transformOrigin: Item.Center

                                Rectangle {
                                    id: charShape
                                    anchors.centerIn: parent
                                    width: 12 * s
                                    height: 12 * s
                                    radius: Math.round(width * 0.24)
                                    color: c.teal
                                    antialiasing: true

                                    property real dotPop: 1.0
                                    scale: dotPop

                                    Component.onCompleted: {
                                        dotPop = 0.82
                                        dotPopAnim.restart()
                                    }

                                    SequentialAnimation {
                                        id: dotPopAnim
                                        NumberAnimation { target: charShape; property: "dotPop"; to: 1.11; duration: 110; easing.type: Easing.OutBack; easing.overshoot: 1.25 }
                                        NumberAnimation { target: charShape; property: "dotPop"; to: 1.0; duration: 170; easing.type: Easing.OutCubic }
                                    }
                                }
                            }
                        }

                        TextInput {
                            id: pwd
                            anchors.fill: parent
                            anchors.leftMargin: 20 * s
                            anchors.rightMargin: 20 * s
                            font.family: root.sansFont
                            font.pixelSize: 18 * s
                            color: "transparent"
                            selectionColor: "transparent"
                            selectedTextColor: "transparent"
                            cursorVisible: false
                            cursorDelegate: Item { width: 0; height: 0 }
                            clip: true
                            echoMode: TextInput.Password
                            inputMethodHints: Qt.ImhHiddenText | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase

                            property bool wasClicked: false
                            onActiveFocusChanged: if (!activeFocus && text.length === 0) wasClicked = false

                            onTextChanged: root.syncModel()

                            Text {
                                anchors.centerIn: parent
                                text: root.errorMessage !== "" ? root.errorMessage : "PASSWORD REQUIRED"
                                font.family: root.sansFont
                                font.pixelSize: 11 * s
                                font.bold: true
                                font.letterSpacing: 1.5 * s
                                color: root.errorMessage !== "" ? c.red : c.subtext0
                                opacity: pwd.text === "" && (!pwd.activeFocus || (!pwd.wasClicked && pwd.text.length === 0)) ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.IBeamCursor
                                onClicked: {
                                    pwd.wasClicked = true;
                                    pwd.forceActiveFocus();
                                }
                            }

                            onAccepted: {
                                if (!root.isQuickshell && pwd.text !== "") {
                                    let currentUser = userHelper.currentItem ? userHelper.currentItem.uLogin : userModel.lastUser;
                                    sddm.login(currentUser, pwd.text, root.sessionIndex);
                                }
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: 12 * s

                        Rectangle {
                            width: userText.implicitWidth + 32 * s
                            height: 38 * s
                            radius: 19 * s
                            color: userMouse.pressed ? c.surface2 : (userMouse.containsMouse ? c.surface1 : c.surface0)
                            border.width: 1
                            border.color: c.surface1
                            scale: userMouse.pressed ? 0.95 : (userMouse.containsMouse ? 1.02 : 1.0)
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                            Text {
                                id: userText
                                anchors.centerIn: parent
                                text: ((userHelper.currentItem && userHelper.currentItem.uName) ? userHelper.currentItem.uName : (userModel.lastUser || "USER")).toUpperCase()
                                font.family: root.sansFont
                                font.pixelSize: 10 * s
                                font.bold: true
                                font.letterSpacing: 1 * s
                                color: c.subtext1
                            }

                            MouseArea {
                                id: userMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!root.isQuickshell && typeof userModel !== "undefined" && userModel.rowCount() > 0) {
                                        root.userIndex = (root.userIndex + 1) % userModel.rowCount();
                                    }
                                }
                            }
                        }

                        Item {
                            width: parent.width - (userText.implicitWidth + 32 * s) - 12 * s
                            height: 38 * s

                            Rectangle {
                                anchors.right: parent.right
                                width: parent.width
                                height: 38 * s
                                radius: 19 * s
                                color: loginMouse.pressed ? c.surface2 : (loginMouse.containsMouse ? c.sapphire : c.blue)
                                scale: loginMouse.pressed ? 0.95 : (loginMouse.containsMouse ? 1.02 : 1.0)
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                                layer.enabled: true
                                layer.effect: Glow { radius: 12; samples: 25; color: c.glow; spread: 0.05 }

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 6 * s

                                    Text {
                                        text: "UNLOCK"
                                        font.family: root.sansFont
                                        font.pixelSize: 10 * s
                                        font.bold: true
                                        font.letterSpacing: 1.5 * s
                                        color: loginMouse.pressed ? c.text : c.crust
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: "➔"
                                        font.family: root.sansFont
                                        font.pixelSize: 11 * s
                                        color: loginMouse.pressed ? c.text : c.crust
                                        anchors.verticalCenter: parent.verticalCenter
                                        transform: Translate {
                                            x: loginMouse.containsMouse ? 3 * s : 0
                                            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: loginMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: pwd.accepted()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
