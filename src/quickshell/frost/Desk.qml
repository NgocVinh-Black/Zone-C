pragma Singleton
import QtQuick

// Which screen is editing its desktop widgets (the bar hides there, like the Widgets artboard).
QtObject {
    property string editingScreen: ""
}
