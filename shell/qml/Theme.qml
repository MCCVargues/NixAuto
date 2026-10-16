pragma Singleton
import QtQuick

// Central colours/sizes so apps and the shell look consistent.
QtObject {
    readonly property color background: "#0b0d10"
    readonly property color surface: "#161a20"
    readonly property color surfaceRaised: "#202631"
    readonly property color text: "#f2f4f7"
    readonly property color textMuted: "#8a93a3"
    readonly property color accent: "#4da3ff"

    readonly property string fontFamily: "Inter"
    readonly property int radius: 18
    readonly property int spacing: 16
    // Minimum touch target in px; keep >= ~9 mm on the physical screen.
    readonly property int touchTarget: 72
}
