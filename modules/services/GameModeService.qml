pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool toggled: false

    property Process enableProcess: Process {
        running: false
        stdout: SplitParser {}
        onExited: (code) => {
            root.toggled = true
            root.updateStatus()
        }
    }

    property Process disableProcess: Process {
        running: false
        stdout: SplitParser {}
        onExited: (code) => {
            root.toggled = false
            root.updateStatus()
        }
    }

    function toggle() {
        if (toggled) {
            disableProcess.command = ["hyprctl", "reload"]
            disableProcess.running = true
        } else {
            enableProcess.command = ["hyprctl", "--batch", "keyword animations:enabled 0; keyword decoration:shadow:enabled 0; keyword decoration:blur:enabled 0; keyword general:gaps_in 0; keyword general:gaps_out 0; keyword general:border_size 1; keyword decoration:rounding 0"]
            enableProcess.running = true
        }
    }

    function updateStatus() {
        checkProcess.running = true
    }

    property Process checkProcess: Process {
        command: ["bash", "-c", "test \"$(hyprctl getoption animations:enabled -j | jq '.int')\" -ne 0"]
        running: false
        stdout: SplitParser {}
        onExited: (code, status) => {
            // If animations are enabled (test succeeds, code === 0), game mode is OFF
            // If animations are disabled (test fails, code !== 0), game mode is ON
            root.toggled = code !== 0
        }
    }

    Component.onCompleted: {
        updateStatus()
    }
}
