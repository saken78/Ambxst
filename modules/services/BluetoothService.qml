pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool enabled: false
    property bool connected: false
    property int connectedDevices: 0

    property Timer updateTimer: Timer {
        interval: 5000
        running: false
        repeat: true
        onTriggered: root.updateStatus()
    }

    property Process toggleProcess: Process {
        running: false
        stdout: SplitParser {}
        onExited: (code) => {
            root.updateStatus()
        }
    }

    function toggle() {
        const newState = !enabled
        toggleProcess.command = ["bluetoothctl", "power", newState ? "on" : "off"]
        toggleProcess.running = true
    }

    function updateStatus() {
        checkPowerProcess.running = true
    }

    property Process checkPowerProcess: Process {
        command: ["bash", "-c", "bluetoothctl show | grep 'Powered:' | awk '{print $2}'"]
        running: false
        stdout: SplitParser {
            onRead: (data) => {
                const output = data ? data.trim() : ""
                root.enabled = output === "yes"
                
                if (root.enabled) {
                    checkConnectedProcess.running = true
                } else {
                    root.connected = false
                    root.connectedDevices = 0
                }
            }
        }
    }

    property Process checkConnectedProcess: Process {
        command: ["bash", "-c", "bluetoothctl devices Connected | wc -l"]
        running: false
        stdout: SplitParser {
            onRead: (data) => {
                const output = data ? data.trim() : "0"
                root.connectedDevices = parseInt(output) || 0
                root.connected = root.connectedDevices > 0
            }
        }
    }

    Component.onCompleted: {
        updateStatus()
        updateTimer.start()
    }
}
