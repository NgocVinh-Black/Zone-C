import QtQuick

// The contract every features/<name>/feature.qml fulfils.
QtObject {
    // Must equal the feature's folder name.
    property string name

    // Component shown on the bar. Leave empty for features without a bar widget.
    property url barWidget

    // Optional popup: { component: url, anchor: "top-left" | "top-right" | "top-center" | "center",
    // width, height, keyboard?: "ondemand" | "exclusive" }.
    // width/height are in 1920x1080 pixels and get scaled. Popups that are typed
    // into (launcher, clipboard) ask for "exclusive", so they take the keyboard
    // the moment a keybind opens them.
    property var popup: null

    // Optional always-on component, loaded once per screen next to the bar, for
    // things that are neither a bar widget nor a popup: notification toasts, OSDs.
    // It draws its own window and is given a `screen` property.
    property url overlay
}
