import QtQuick

Item {
    id: tile

    property string label
    property string icon
    signal activated()

    Rectangle {
        anchors.fill: parent
        anchors.margins: Theme.spacing / 2
        radius: Theme.radius
        color: tap.pressed ? Theme.accent : Theme.surfaceRaised

        Column {
            anchors.centerIn: parent
            spacing: 8

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: tile.icon
                color: Theme.text
                font.pixelSize: tile.height * 0.3
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: tile.label
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(18, tile.height * 0.12)
            }
        }

        TapHandler {
            id: tap
            onTapped: tile.activated()
        }
    }
}
