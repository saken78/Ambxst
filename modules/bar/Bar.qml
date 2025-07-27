import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../workspaces"
import qs.modules.theme
import qs.modules.clock
import qs.modules.systray
import "../launcher"

PanelWindow {
    id: panel

    anchors {
        top: true
        left: true
        right: true
        // bottom: true
    }

    color: "transparent"

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    exclusiveZone: 40
    implicitHeight: 44

    Rectangle {
        id: bar
        anchors.fill: parent
        color: "transparent"

        // Left side of bar
        RowLayout {
            id: leftSide
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 4
            spacing: 4

            LauncherButton {
                id: launcherButton
            }

            Workspaces {
                bar: QtObject {
                    property var screen: panel.screen
                }
            }
        }

        // Right side of bar
        RowLayout {
            id: rightSide
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 4
            spacing: 4

            SysTray {
                bar: panel
            }

            Clock {
                id: clockComponent
            }
        }
    }
}
