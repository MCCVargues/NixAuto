import QtQuick

// Home screen: big clock/date on the left, app drawer on the right.
// Under cage the window is always fullscreen; on a desktop it's a 1280x720
// window for development (`nix run .#shell`).
Window {
    id: root
    width: 1280
    height: 720
    visible: true
    title: "NixAuto"
    color: Theme.background

    ClockPane {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: drawer.left
    }

    AppDrawer {
        id: drawer
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        openWidth: Math.round(root.width * 0.38)
    }
}
