pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtMultimedia
import Quickshell
import qs.modules.theme
import qs.modules.components
import qs.config

Item {
    id: root
    implicitHeight: content.implicitHeight + 24
    width: 300

    // --- State & Logic ---
    property bool isRunning: false
    property bool isWorkSession: true
    property bool alarmActive: false
    
    // Internal countdown state
    property int timeLeft: Config.system.pomodoro.workTime

    function toggleTimer() {
        if (alarmActive) {
            stopAlarm();
            nextSession();
            return;
        }
        isRunning = !isRunning;
    }

    function resetTimer() {
        stopAlarm();
        isRunning = false;
        isWorkSession = true;
        timeLeft = Config.system.pomodoro.workTime;
    }

    function startAlarm() {
        isRunning = false;
        alarmActive = true;
        alarmSound.loops = Config.system.pomodoro.autoStart ? 4 : SoundEffect.Infinite;
        alarmSound.play();
    }

    function stopAlarm() {
        alarmSound.stop();
        alarmActive = false;
    }

    function nextSession() {
        isWorkSession = !isWorkSession;
        timeLeft = isWorkSession ? Config.system.pomodoro.workTime : Config.system.pomodoro.restTime;
        if (Config.system.pomodoro.autoStart) {
            isRunning = true;
        }
    }

    SoundEffect {
        id: alarmSound
        source: Quickshell.shellDir + "/assets/sound/polite-warning-tone.wav"
        onPlayingChanged: {
            if (!playing && alarmActive && Config.system.pomodoro.autoStart) {
                stopAlarm();
                nextSession();
            }
        }
    }

    Timer {
        id: countdownTimer
        interval: 1000
        running: root.isRunning && root.timeLeft > 0
        repeat: true
        onTriggered: {
            if (root.timeLeft > 0) {
                root.timeLeft--;
                if (root.timeLeft === 0) {
                    startAlarm();
                }
            }
        }
    }

    // --- UI Layout ---
    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // Top Row: Small Configs
        RowLayout {
            Layout.fillWidth: true
            
            StyledRect {
                variant: "common"
                Layout.preferredHeight: 28
                Layout.preferredWidth: 110
                radius: Styling.radius(-4)
                
                Text {
                    anchors.centerIn: parent
                    text: root.isWorkSession ? "Work Session" : "Rest Session"
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-1)
                    font.weight: Font.Bold
                    color: mouseAreaToggle.containsMouse ? Styling.srItem("overprimary") : Colors.overBackground
                }
                
                MouseArea {
                    id: mouseAreaToggle
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: !root.isRunning && !root.alarmActive
                    onClicked: {
                        root.isWorkSession = !root.isWorkSession;
                        root.timeLeft = root.isWorkSession ? Config.system.pomodoro.workTime : Config.system.pomodoro.restTime;
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Auto Toggle
            RowLayout {
                spacing: 6
                Text {
                    text: "Auto"
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-2)
                    color: Colors.outline
                }
                Item {
                    width: 32; height: 18
                    Rectangle {
                        anchors.fill: parent
                        radius: 9
                        color: Config.system.pomodoro.autoStart ? Styling.srItem("overprimary") : Colors.surfaceBright
                        opacity: Config.system.pomodoro.autoStart ? 1.0 : 0.4
                        Rectangle {
                            x: Config.system.pomodoro.autoStart ? parent.width - 16 : 2
                            y: 2; width: 14; height: 14; radius: 7
                            color: Colors.background
                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: Config.system.pomodoro.autoStart = !Config.system.pomodoro.autoStart
                    }
                }
            }

            // Reset
            StyledRect {
                variant: "common"
                implicitWidth: 28; implicitHeight: 28
                radius: Styling.radius(-4)
                Text {
                    anchors.centerIn: parent
                    text: Icons.arrowCounterClockwise
                    font.family: Icons.font; font.pixelSize: 14
                    color: Colors.overBackground
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.resetTimer()
                }
            }
        }

        // Stack-like view for Timer Inputs
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            clip: true

            // Animación de entrada/salida para el tipo de sesión
            ColumnLayout {
                id: timerInputs
                anchors.centerIn: parent
                spacing: 4

                RowLayout {
                    spacing: 4
                    Layout.alignment: Qt.AlignHCenter
                    
                    TimerInput {
                        id: minIn
                        value: Math.floor(root.timeLeft / 60)
                        onValueUpdated: val => {
                            let newSeconds = (val * 60) + (root.timeLeft % 60);
                            root.timeLeft = newSeconds;
                            if (!root.isRunning) {
                                if (root.isWorkSession) Config.system.pomodoro.workTime = newSeconds;
                                else Config.system.pomodoro.restTime = newSeconds;
                            }
                        }
                    }
                    
                    Text {
                        text: ":"
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(8)
                        font.weight: Font.Bold
                        color: root.alarmActive ? Styling.srItem("overprimary") : Colors.overBackground
                        Layout.topMargin: -6
                    }
                    
                    TimerInput {
                        id: secIn
                        value: root.timeLeft % 60
                        onValueUpdated: val => {
                            let newSeconds = (Math.floor(root.timeLeft / 60) * 60) + val;
                            root.timeLeft = newSeconds;
                            if (!root.isRunning) {
                                if (root.isWorkSession) Config.system.pomodoro.workTime = newSeconds;
                                else Config.system.pomodoro.restTime = newSeconds;
                            }
                        }
                    }
                }
            }

            // Indicador visual de la sesión activa (Work vs Rest)
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                height: 2; width: 40
                radius: 1
                color: Styling.srItem("overprimary")
                x: root.isWorkSession ? parent.width/2 - 50 : parent.width/2 + 10
                
                Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            }
        }

        // Quick Adjust & Start
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ControlBtn {
                text: "-1m"
                onClicked: {
                    if (root.timeLeft >= 60) {
                        root.timeLeft -= 60;
                        if (!root.isRunning) {
                            if (root.isWorkSession) Config.system.pomodoro.workTime = Math.max(60, Config.system.pomodoro.workTime - 60);
                            else Config.system.pomodoro.restTime = Math.max(60, Config.system.pomodoro.restTime - 60);
                        }
                    }
                }
            }

            StyledRect {
                id: playBtn
                variant: root.alarmActive ? "primary" : (root.isRunning ? "focus" : "common")
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                radius: Styling.radius(0)
                
                Text {
                    anchors.centerIn: parent
                    text: root.alarmActive ? "STOP ALARM" : (root.isRunning ? "PAUSE" : "START " + (root.isWorkSession ? "WORK" : "REST"))
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(0)
                    font.weight: Font.Black
                    font.letterSpacing: 1
                    color: playBtn.item
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.toggleTimer()
                }
            }

            ControlBtn {
                text: "+1m"
                onClicked: {
                    root.timeLeft += 60;
                    if (!root.isRunning) {
                        if (root.isWorkSession) Config.system.pomodoro.workTime += 60;
                        else Config.system.pomodoro.restTime += 60;
                    }
                }
            }
        }
    }

    // --- Sub-components ---
    component TimerInput: TextField {
        id: tIn
        property int value: 0
        signal valueUpdated(int newValue)
        
        text: value.toString().padStart(2, '0')
        onActiveFocusChanged: if (!activeFocus) text = value.toString().padStart(2, '0')
        
        font.family: Config.theme.monoFont
        font.pixelSize: Styling.fontSize(8)
        font.weight: Font.Bold
        color: root.alarmActive ? (Math.floor(Date.now() / 500) % 2 === 0 ? Styling.srItem("overprimary") : Colors.overBackground) : Colors.overBackground
        
        background: Item {}
        padding: 0; leftPadding: 0; rightPadding: 0
        horizontalAlignment: TextInput.AlignHCenter
        maximumLength: 2
        validator: IntValidator { bottom: 0; top: 99 }
        selectByMouse: true
        
        onTextEdited: {
            let v = parseInt(text);
            if (!isNaN(v)) {
                tIn.valueUpdated(v);
            }
        }
        
        onEditingFinished: {
            let v = parseInt(text) || 0;
            tIn.valueUpdated(v);
            text = v.toString().padStart(2, '0');
        }
        
        Layout.preferredWidth: 60
        
        Timer {
            interval: 500
            running: root.alarmActive
            repeat: true
            onTriggered: tIn.update()
        }
    }

    component ControlBtn: StyledRect {
        id: cBtn
        property string text: ""
        signal clicked()
        
        variant: "common"
        implicitWidth: 44; implicitHeight: 40
        radius: Styling.radius(-4)
        
        Text {
            anchors.centerIn: parent
            text: cBtn.text
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(-1)
            color: mouseA.containsMouse ? Styling.srItem("overprimary") : Colors.overBackground
        }
        
        MouseArea {
            id: mouseA
            anchors.fill: parent
            hoverEnabled: true
            onClicked: cBtn.clicked()
        }
    }
}
