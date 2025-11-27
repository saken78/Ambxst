import QtQuick
import Quickshell
import qs.modules.components
import qs.config

ShellRoot {
    PanelWindow {
        anchors {
            top: true
            left: true
        }
        width: 800
        height: 600
        color: "transparent"

        StyledRect {
            anchors.fill: parent
            anchors.margins: 20
            variant: "primary"
            enableShadow: true
        }
    }
}
