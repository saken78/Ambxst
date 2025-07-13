import QtQuick
import "../theme"

Text {
    id: timeDisplay

    property string currentTime: ""

    text: currentTime
    color: Colors.foreground
    font.pixelSize: 12
    font.family: "Iosevka Nerd Font"

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var now = new Date();
            timeDisplay.currentTime = Qt.formatDateTime(now, "hh:mm:ss");
        }
    }
}