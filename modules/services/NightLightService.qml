pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool active: false

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
            root.active = false
            root.updateStatus()
        }
    }

    property Process startProcess: Process {
        running: false
        stdout: SplitParser {}
        onExited: (code) => {
            root.active = true
            root.updateStatus()
        }
    }

    function toggle() {
        if (active) {
            killProcess.command = ["pkill", "hyprsunset"]
            killProcess.running = true
        } else {
            startProcess.command = ["hyprsunset", "-t", "4000"]
            startProcess.running = true
        }
    }

    function updateStatus() {
        checkProcess.running = true
    }

    property Process checkProcess: Process {
        command: ["pgrep", "hyprsunset"]
        running: false
        stdout: SplitParser {}
        onExited: (code, status) => {
            root.active = code === 0
        }
    }

    Component.onCompleted: {
        updateStatus()
        updateTimer.start()
    }
}
