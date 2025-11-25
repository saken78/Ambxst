pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool wifiEnabled: false
    property string wifiStatus: "disabled"
    property int signalStrength: 0
    
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
    
    function toggleWifi() {
        const newState = !wifiEnabled
        toggleProcess.command = ["nmcli", "radio", "wifi", newState ? "on" : "off"]
        toggleProcess.running = true
    }

    function updateStatus() {
        checkWifiProcess.running = true
    }

    property Process checkWifiProcess: Process {
        command: ["nmcli", "radio", "wifi"]
        running: false
        stdout: SplitParser {
            onRead: (data) => {
                const output = data ? data.trim() : ""
                root.wifiEnabled = output === "enabled"
                root.wifiStatus = output
                
                if (root.wifiEnabled) {
                    checkSignalProcess.running = true
                } else {
                    root.signalStrength = 0
                }
            }
        }
    }

    property Process checkSignalProcess: Process {
        command: ["bash", "-c", "nmcli -t -f ACTIVE,SIGNAL device wifi | grep '^yes' | cut -d':' -f2"]
        running: false
        stdout: SplitParser {
            onRead: (data) => {
                const output = data ? data.trim() : "0"
                root.signalStrength = parseInt(output) || 0
            }
        }
    }

    Component.onCompleted: {
        updateStatus()
        updateTimer.start()
    }
}
