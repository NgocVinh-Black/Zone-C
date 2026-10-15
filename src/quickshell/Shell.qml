import QtQuick
import Quickshell

ShellRoot {
    readonly property bool performanceMode: !!(Config.getSetting("general", {}).performance)
    readonly property bool quickactionsEnabled: Config.getSetting("general", {}).quickactions !== false
    readonly property bool dockEnabled: Config.getSetting("dock", {}).enabled !== false
    readonly property bool zoneAnimated: ZoneStyle.animated

    Connections {
        target: Quickshell
        function onReloadCompleted() { Quickshell.inhibitReloadPopup() }
        function onReloadFailed(errorString) { Quickshell.inhibitReloadPopup() }
    }

    ScreenshotOverlay {}
    Main {}
    Bar {}
    Lock {}

    Launcher {}
    Clipboard {}    

    Polkit {}
    PairDialog {}
    FrostOverview {}
    FrostTray {}
    FrostEmoji {}
    FrostPower {}
    CloseConfirm {}
    KeybindsHelp {}
    PopoutManager {}

    Loader {
        active: dockEnabled
        sourceComponent: Dock {}
    }

    Loader {
        active: !performanceMode
        sourceComponent: Idle {}
    }
    Loader {
        active: !performanceMode
        sourceComponent: FrostDesktop {}
    }
    Loader {
        active: !performanceMode
        sourceComponent: WallpaperEngine {}
    }
    Loader {
        active: !performanceMode
        sourceComponent: ElectricBorder {}
    }
    Loader {
        active: !performanceMode && quickactionsEnabled
        sourceComponent: Floating {}
    }

    Component.onCompleted: {
        FirstLaunch.checkFirstLaunch();
    }
}
