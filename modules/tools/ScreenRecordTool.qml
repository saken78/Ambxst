import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config

PanelWindow {
    id: recordPopup

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // Visible only when explicitly opened
    visible: state !== "idle"
    exclusionMode: ExclusionMode.Ignore

    property string state: "idle" // idle, active

    // Audio State
    property bool recordAudioOutput: false
    property bool recordAudioInput: false

    property var modes: [
        {
            name: "audioOutput",
            icon: Icons.speakerHigh,
            tooltip: "Toggle Audio Output",
            type: "toggle",
            active: recordPopup.recordAudioOutput
        },
        {
            name: "audioInput",
            icon: Icons.mic,
            tooltip: "Toggle Microphone",
            type: "toggle",
            active: recordPopup.recordAudioInput
        },
        {
            type: "separator"
        },
        {
            name: "record",
            icon: Icons.aperture,
            tooltip: "Start Recording"
        }
    ]

    function open() {
        recordPopup.state = "active";
    }

    function close() {
        recordPopup.state = "idle";
    }

    function executeCapture() {
        ScreenRecorder.startRecording(recordAudioOutput, recordAudioInput);
        recordPopup.close();
    }

    // Mask (Dim background)
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: recordPopup.visible ? 0.4 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        
        MouseArea {
            anchors.fill: parent
            onClicked: recordPopup.close()
        }
    }

    // Focus grabber
    HyprlandFocusGrab {
        id: focusGrab
        windows: [recordPopup]
        active: recordPopup.visible
    }

    // Main Content
    FocusScope {
        id: mainFocusScope
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: recordPopup.close()

        // Controls UI (Centered)
        Rectangle {
            id: controlsBar
            anchors.centerIn: parent

            width: modeGrid.width + 32
            height: modeGrid.height + 32

            radius: Styling.radius(20)
            color: Colors.background
            border.color: Colors.surface
            border.width: 1

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                preventStealing: true
            }

            ActionGrid {
                id: modeGrid
                anchors.centerIn: parent

                // Map the modes to actions
                actions: recordPopup.modes.map(m => {
                    if (m.type === "separator")
                        return m;

                    var newM = Object.assign({}, m);
                    if (m.name === "audioOutput") {
                        newM.variant = recordPopup.recordAudioOutput ? "primary" : "surface";
                        newM.icon = recordPopup.recordAudioOutput ? Icons.speakerHigh : Icons.speakerSlash;
                    } else if (m.name === "audioInput") {
                        newM.variant = recordPopup.recordAudioInput ? "primary" : "surface";
                        newM.icon = recordPopup.recordAudioInput ? Icons.mic : Icons.micSlash;
                    } else if (m.name === "record") {
                        newM.variant = "primary";
                    }
                    return newM;
                })

                buttonSize: 48
                iconSize: 24
                spacing: 10

                onActionTriggered: action => {
                    if (action.name === "audioOutput") {
                        recordPopup.recordAudioOutput = !recordPopup.recordAudioOutput;
                    } else if (action.name === "audioInput") {
                        recordPopup.recordAudioInput = !recordPopup.recordAudioInput;
                    } else if (action.name === "record") {
                        recordPopup.executeCapture();
                    }
                }
            }
        }
    }
}
