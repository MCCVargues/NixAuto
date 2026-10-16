import QtQuick

// Right-hand app drawer. Tap the handle (or swipe it) to collapse/expand.
// The entries are placeholders until app flakes register themselves
// (see docs/apps.md).
Rectangle {
    id: drawer

    property int openWidth: 480
    property bool open: true
    readonly property int handleWidth: 40

    width: open ? openWidth : handleWidth
    color: Theme.surface
    clip: true

    Behavior on width {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    // Handle strip along the left edge.
    Item {
        id: handle
        width: drawer.handleWidth
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        Rectangle {
            anchors.centerIn: parent
            width: 6
            height: 64
            radius: 3
            color: Theme.textMuted
        }

        TapHandler {
            onTapped: drawer.open = !drawer.open
        }

        DragHandler {
            target: null
            xAxis.enabled: true
            yAxis.enabled: false
            onActiveChanged: {
                if (active)
                    return
                if (translation.x < -30)
                    drawer.open = true
                else if (translation.x > 30)
                    drawer.open = false
            }
        }
    }

    GridView {
        id: grid
        anchors.fill: parent
        anchors.margins: Theme.spacing
        anchors.leftMargin: drawer.handleWidth
        visible: drawer.width > drawer.handleWidth + 1

        readonly property int columns: 2
        // Based on openWidth, not the live width, so tiles don't reflow
        // while the drawer animates.
        cellWidth: Math.floor((drawer.openWidth - drawer.handleWidth - Theme.spacing) / columns)
        cellHeight: cellWidth * 0.8
        interactive: contentHeight > height

        model: ListModel {
            ListElement { name: "Media"; glyph: "♪" }
            ListElement { name: "Navigation"; glyph: "➤" }
            ListElement { name: "Audio"; glyph: "≋" }
            ListElement { name: "Phone"; glyph: "✆" }
            ListElement { name: "Vehicle"; glyph: "⚙" }
            ListElement { name: "Settings"; glyph: "☰" }
        }

        delegate: AppTile {
            required property string name
            required property string glyph
            width: grid.cellWidth
            height: grid.cellHeight
            label: name
            icon: glyph
            onActivated: console.log("launch", name)
        }
    }
}
