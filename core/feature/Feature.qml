import QtQuick

// The contract every features/<name>/feature.qml fulfils.
QtObject {
    // Must equal the feature's folder name.
    property string name

    // Component shown on the bar. Leave empty for features without a bar widget.
    property url barWidget

    // Optional popup: { component: url, anchor: "top-left" | "top-right" | "top-center" | "center", width, height }.
    // width/height are in 1920x1080 pixels and get scaled.
    property var popup: null
}
