pragma Singleton

import QtQuick
import Quickshell
import qs.core.state

// Design tokens. Sizes follow Serpantinum v1 and are scaled to the screen.
Singleton {
    readonly property QtObject bar: QtObject {
        readonly property int height: Scale.s(48)
        readonly property int marginTop: Scale.s(8)
        readonly property int marginSide: Scale.s(4)
        readonly property int zoneGap: Scale.s(12)
        readonly property int enterOffset: Scale.s(30)
        readonly property int enterDuration: 800
        readonly property real enterOvershoot: 1.1
        readonly property int enterLeftDelay: 10
        readonly property int enterCenterDelay: 150
        readonly property int enterRightDelay: 250
    }

    readonly property QtObject block: QtObject {
        readonly property int radius: Scale.s(14)
        readonly property real opacity: 0.75
        readonly property int borderWidth: 1
        readonly property real borderAlpha: 0.05
        readonly property real borderAlphaStatic: 0.08
        readonly property real borderAlphaHover: 0.15
        readonly property real hoverOpacity: 0.95
        readonly property int gap: Scale.s(4)
        readonly property int paddingX: Scale.s(10)
        readonly property int itemGap: Scale.s(8)
    }

    readonly property QtObject pill: QtObject {
        readonly property int height: Scale.s(34)
        readonly property int radius: Scale.s(10)
        readonly property int paddingX: Scale.s(12)
        readonly property int spacing: Scale.s(8)
        readonly property int maxTextWidth: Scale.s(100)
        readonly property real alpha: 0.4
        readonly property real hoverAlpha: 0.6
        readonly property real hoverScale: 1.05
        readonly property real accentLighter: 1.3
        readonly property int enterOffset: Scale.s(15)
        readonly property int enterStagger: 50
    }

    readonly property QtObject iconBlock: QtObject {
        readonly property int size: Scale.s(48)
        readonly property real hoverScale: 1.05
    }

    readonly property QtObject workspace: QtObject {
        readonly property int size: Scale.s(32)
        readonly property int radius: Scale.s(10)
        readonly property int spacing: Scale.s(6)
        readonly property real fillAlpha: 0.9
        readonly property real hoverScale: 1.08
        readonly property int enterStagger: 60
    }

    readonly property QtObject media: QtObject {
        readonly property int art: Scale.s(32)
        readonly property int artRadius: Scale.s(8)
        readonly property real artTintAlpha: 0.2
        readonly property int padding: Scale.s(12)
        readonly property int spacing: Scale.s(16)
        readonly property int spacingCompact: Scale.s(8)
        readonly property int infoSpacing: Scale.s(10)
        readonly property int titleWidth: Scale.s(180)
        readonly property int titleWidthCompact: Scale.s(120)
        readonly property int control: Scale.s(24)
        readonly property int controlMain: Scale.s(28)
        readonly property int controlIcon: Scale.s(26)
        readonly property int controlIconMain: Scale.s(30)
    }

    readonly property QtObject clock: QtObject {
        readonly property int paddingX: Scale.s(8)
        readonly property int weatherGap: Scale.s(24)
        readonly property int typeInterval: 40
        readonly property real hoverScale: 1.03
    }

    readonly property QtObject tray: QtObject {
        readonly property int icon: Scale.s(18)
        readonly property int spacing: Scale.s(10)
        readonly property int paddingX: Scale.s(2)
        readonly property real idleOpacity: 0.8
        readonly property real hoverScale: 1.15
    }

    readonly property QtObject popup: QtObject {
        readonly property int marginTop: Scale.s(70)
        readonly property int edgeLeft: Scale.s(12)
        readonly property int edgeRight: Scale.s(20)
        readonly property int radius: Scale.s(20)
        readonly property int padding: Scale.s(25)
        readonly property real introScale: 0.92
        readonly property int introLift: Scale.s(15)
    }

    readonly property QtObject font: QtObject {
        readonly property string text: "JetBrains Mono"
        readonly property string icon: "Iosevka Nerd Font"
        readonly property QtObject size: QtObject {
            readonly property int tiny: Scale.s(10)
            readonly property int small: Scale.s(11)
            readonly property int label: Scale.s(12)
            readonly property int pill: Scale.s(13)
            readonly property int body: Scale.s(14)
            readonly property int clock: Scale.s(16)
            readonly property int icon: Scale.s(16)
            readonly property int temperature: Scale.s(17)
            readonly property int title: Scale.s(18)
            readonly property int large: Scale.s(20)
            readonly property int iconLarge: Scale.s(22)
            readonly property int weatherIcon: Scale.s(24)
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
