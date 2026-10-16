import QtQuick

Item {
    id: pane

    property date now: new Date()

    Timer {
        // Tick on the second so the minute flips on time.
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: pane.now = new Date()
    }

    Column {
        anchors.centerIn: parent
        spacing: Theme.spacing

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(pane.now, "HH:mm")
            color: Theme.text
            font.family: Theme.fontFamily
            font.weight: Font.Light
            font.pixelSize: Math.min(pane.height * 0.42, pane.width * 0.3)
            font.features: ({ "tnum": 1 }) // fixed-width digits: no jitter
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: pane.now.toLocaleDateString(Qt.locale(), "dddd d MMMM yyyy")
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Math.min(pane.height * 0.07, pane.width * 0.05)
        }
    }
}
