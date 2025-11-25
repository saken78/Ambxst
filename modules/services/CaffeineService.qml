pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool inhibit: false

    property Timer updateTimer: Timer {
        interval: 3000
        running: false
        repeat: true
        onTriggered: root.updateStatus()
    }

    property Process killProcess: Process {
        running: false
        stdout: SplitParser {}
        onExited: (code) => {
            root.inhibit = true
            root.updateStatus()
        }
    }

    property Process startProcess: Process {
        running: false
        stdout: SplitParser {}
        onExited: (code) => {
            root.inhibit = false
            root.updateStatus()
        }
    }

    function toggleInhibit() {
        if (inhibit) {
            // When inhibit is ON, we kill hypridle to allow system to sleep again
            killProcess.command = ["pkill", "hypridle"]
            killProcess.running = true
        } else {
            // When inhibit is OFF, we start hypridle
            startProcess.command = ["sh", "-c", "hypridle &"]
            startProcess.running = true
        }
    }

    function updateStatus() {
        checkProcess.running = true
    }

    property Process checkProcess: Process {
        command: ["pgrep", "hypridle"]
        running: false
        stdout: SplitParser {}
        onExited: (code, status) => {
            // If hypridle is running (code === 0), then inhibit is OFF
            // If hypridle is NOT running (code !== 0), then inhibit is ON
            root.inhibit = code !== 0
        }
    }

    Component.onCompleted: {
        updateStatus()
        updateTimer.start()
    }
}
