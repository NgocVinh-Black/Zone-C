pragma Singleton

import QtQuick
import Quickshell
import qs.core.state

// Design tokens. Sizes follow Serpantinum v1 and are scaled to the screen.
Singleton {
    readonly property QtObject bar: QtObject {
        readonly property int height: UiScale.s(48)
        readonly property int marginTop: UiScale.s(8)
        readonly property int marginSide: UiScale.s(4)
        readonly property int zoneGap: UiScale.s(12)
        readonly property int enterOffset: UiScale.s(30)
        readonly property int enterDuration: 800
        readonly property real enterOvershoot: 1.1
        readonly property int enterLeftDelay: 10
        readonly property int enterCenterDelay: 150
        readonly property int enterRightDelay: 250
    }

    readonly property QtObject block: QtObject {
        readonly property int radius: UiScale.s(14)
        readonly property real opacity: 0.75
        readonly property int borderWidth: 1
        readonly property real borderAlpha: 0.05
        readonly property real borderAlphaStatic: 0.08
        readonly property real borderAlphaHover: 0.15
        readonly property real hoverOpacity: 0.95
        readonly property int gap: UiScale.s(4)
        readonly property int paddingX: UiScale.s(10)
        readonly property int itemGap: UiScale.s(8)
    }

    readonly property QtObject pill: QtObject {
        readonly property int height: UiScale.s(34)
        readonly property int radius: UiScale.s(10)
        readonly property int paddingX: UiScale.s(12)
        readonly property int spacing: UiScale.s(8)
        readonly property int maxTextWidth: UiScale.s(100)
        readonly property real alpha: 0.4
        readonly property real hoverAlpha: 0.6
        readonly property real hoverScale: 1.05
        readonly property real accentLighter: 1.3
        readonly property int enterOffset: UiScale.s(15)
        readonly property int enterStagger: 50
    }

    readonly property QtObject iconBlock: QtObject {
        readonly property int size: UiScale.s(48)
        readonly property real hoverScale: 1.05
    }

    readonly property QtObject workspace: QtObject {
        readonly property int size: UiScale.s(32)
        readonly property int radius: UiScale.s(10)
        readonly property int spacing: UiScale.s(6)
        readonly property real fillAlpha: 0.9
        readonly property real hoverScale: 1.08
        readonly property int enterStagger: 60
    }

    readonly property QtObject media: QtObject {
        readonly property int art: UiScale.s(32)
        readonly property int artRadius: UiScale.s(8)
        readonly property real artTintAlpha: 0.2
        readonly property int padding: UiScale.s(12)
        readonly property int spacing: UiScale.s(16)
        readonly property int spacingCompact: UiScale.s(8)
        readonly property int infoSpacing: UiScale.s(10)
        readonly property int titleWidth: UiScale.s(180)
        readonly property int titleWidthCompact: UiScale.s(120)
        readonly property int control: UiScale.s(24)
        readonly property int controlMain: UiScale.s(28)
        readonly property int controlIcon: UiScale.s(26)
        readonly property int controlIconMain: UiScale.s(30)
    }

    readonly property QtObject clock: QtObject {
        readonly property int paddingX: UiScale.s(8)
        readonly property int weatherGap: UiScale.s(24)
        readonly property int typeInterval: 40
        readonly property real hoverScale: 1.03
    }

    readonly property QtObject tray: QtObject {
        readonly property int icon: UiScale.s(18)
        readonly property int spacing: UiScale.s(10)
        readonly property int paddingX: UiScale.s(2)
        readonly property real idleOpacity: 0.8
        readonly property real hoverScale: 1.15
    }

    readonly property QtObject popup: QtObject {
        readonly property int marginTop: UiScale.s(70)
        readonly property int edgeLeft: UiScale.s(12)
        readonly property int edgeRight: UiScale.s(20)
        readonly property int radius: UiScale.s(20)
        readonly property int padding: UiScale.s(25)
        readonly property real introScale: 0.92
        readonly property int introLift: UiScale.s(15)
    }

    readonly property QtObject font: QtObject {
        readonly property string text: "JetBrains Mono"
        readonly property string icon: "Iosevka Nerd Font"
        readonly property QtObject size: QtObject {
            readonly property int tiny: UiScale.s(10)
            readonly property int small: UiScale.s(11)
            readonly property int label: UiScale.s(12)
            readonly property int pill: UiScale.s(13)
            readonly property int body: UiScale.s(14)
            readonly property int clock: UiScale.s(16)
            readonly property int icon: UiScale.s(16)
            readonly property int temperature: UiScale.s(17)
            readonly property int title: UiScale.s(18)
            readonly property int large: UiScale.s(20)
            readonly property int iconLarge: UiScale.s(22)
            readonly property int weatherIcon: UiScale.s(24)
        }
    }

    readonly property QtObject anim: QtObject {
        readonly property int fast: 150
        readonly property int normal: 250
        readonly property int medium: 400
        readonly property int slow: 500
        readonly property int color: 250
        readonly property int morph: 230
        readonly property int morphSwitch: 210
        readonly property int exit: 160
        readonly property int orbit: 90000
    }
}
