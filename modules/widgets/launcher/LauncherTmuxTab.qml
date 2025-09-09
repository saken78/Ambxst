import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.theme
import qs.modules.components
import qs.modules.globals
import qs.modules.services
import qs.config

Rectangle {
    id: root

    property string searchText: ""
    property bool showResults: searchText.length > 0
    property int selectedIndex: -1
    property var tmuxSessions: []
    property alias filteredSessions: listModel.sessions
    
    signal itemSelected

    // Model para hacer la lista observable
    QtObject {
        id: listModel
        property var sessions: []
        
        function updateSessions(newSessions) {
            sessions = newSessions;
            console.log("DEBUG: listModel updated with", sessions.length, "sessions");
        }
    }

    onSelectedIndexChanged: {
        if (selectedIndex === -1 && resultsList.count > 0) {
            resultsList.positionViewAtIndex(0, ListView.Beginning);
        }
    }

    onSearchTextChanged: {
        updateFilteredSessions();
    }

    function clearSearch() {
        searchText = "";
        selectedIndex = -1;
        searchInput.focusInput();
        updateFilteredSessions();
    }

    function focusSearchInput() {
        searchInput.focusInput();
    }

    function updateFilteredSessions() {
        console.log("DEBUG: updateFilteredSessions called. searchText:", searchText, "tmuxSessions.length:", tmuxSessions.length);
        
        var newFilteredSessions = [];
        
        // Filtrar sesiones que coincidan con el texto de búsqueda
        if (searchText.length === 0) {
            newFilteredSessions = tmuxSessions.slice(); // Copia del array
        } else {
            newFilteredSessions = tmuxSessions.filter(function(session) {
                return session.name.toLowerCase().includes(searchText.toLowerCase());
            });
            
            // Verificar si existe una sesión con el nombre exacto
            let exactMatch = tmuxSessions.find(function(session) {
                return session.name.toLowerCase() === searchText.toLowerCase();
            });
            
            // Si no hay coincidencia exacta y hay texto de búsqueda, agregar opción para crear la sesión específica
            if (!exactMatch && searchText.length > 0) {
                newFilteredSessions.push({
                    name: `Create session "${searchText}"`,
                    isCreateSpecificButton: true,
                    sessionNameToCreate: searchText,
                    icon: "terminal"
                });
            }
        }
        
        console.log("DEBUG: newFilteredSessions after filter:", newFilteredSessions.length);
        
        // Solo agregar el botón "Create new session" cuando NO hay texto de búsqueda
        if (searchText.length === 0) {
            newFilteredSessions.push({
                name: "Create new session",
                isCreateButton: true,
                icon: "terminal"
            });
        }
        
        console.log("DEBUG: newFilteredSessions after adding create button:", newFilteredSessions.length);
        
        // Actualizar el modelo
        listModel.updateSessions(newFilteredSessions);
        
        // Auto-highlight first item when text is entered
        if (searchText.length > 0 && newFilteredSessions.length > 0) {
            selectedIndex = 0;
            resultsList.currentIndex = 0;
        } else if (searchText.length === 0) {
            selectedIndex = -1;
            resultsList.currentIndex = -1;
        }
        
        console.log("DEBUG: Final selectedIndex:", selectedIndex, "resultsList will have count:", newFilteredSessions.length);
    }

    function refreshTmuxSessions() {
        tmuxProcess.running = true;
    }

    function createTmuxSession(sessionName) {
        if (sessionName) {
            // Crear la sesión con nombre específico
            createProcess.command = ["bash", "-c", `kitty -e tmux new -s "${sessionName}" & disown`];
        } else {
            // Crear sesión sin nombre (tmux se encarga del nombre automático)
            createProcess.command = ["bash", "-c", `kitty -e tmux & disown`];
        }
        createProcess.running = true;
        root.itemSelected(); // Cerrar el notch
    }

    function attachToSession(sessionName) {
        // Ejecutar terminal con tmux attach de forma independiente (detached)
        attachProcess.command = ["bash", "-c", `kitty -e tmux attach-session -t "${sessionName}" & disown`];
        attachProcess.running = true;
    }

    implicitWidth: 400
    implicitHeight: mainLayout.implicitHeight
    color: "transparent"

    Behavior on height {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutQuart
        }
    }

    // Proceso para obtener lista de sesiones de tmux
    Process {
        id: tmuxProcess
        command: ["tmux", "list-sessions", "-F", "#{session_name}"]
        running: false

        stdout: StdioCollector {
            id: tmuxCollector
            waitForEnd: true

            onStreamFinished: {
                let sessions = [];
                let lines = text.trim().split('\n');
                for (let line of lines) {
                    if (line.trim().length > 0) {
                        sessions.push({
                            name: line.trim(),
                            isCreateButton: false,
                            icon: "terminal"
                        });
                    }
                }
                root.tmuxSessions = sessions;
                root.updateFilteredSessions();
            }
        }

        onExited: function (exitCode) {
            if (exitCode !== 0) {
                // No hay sesiones o tmux no está disponible
                root.tmuxSessions = [];
                root.updateFilteredSessions();
            }
        }
    }

    // Proceso para crear nuevas sesiones
    Process {
        id: createProcess
        running: false

        onExited: function (code) {
            if (code === 0) {
                // Sesión creada exitosamente, refrescar la lista
                root.refreshTmuxSessions();
            }
        }
    }

    // Proceso para abrir terminal con tmux attach
    Process {
        id: attachProcess
        running: false

        onStarted: function () {
            root.itemSelected();
        }
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: 8

        // Search input
        SearchInput {
            id: searchInput
            Layout.fillWidth: true
            text: root.searchText
            placeholderText: "Search or create tmux session..."
            iconText: ""

            onSearchTextChanged: text => {
                root.searchText = text;
            }

            onAccepted: {
                console.log("DEBUG: Enter pressed! searchText:", root.searchText, "selectedIndex:", root.selectedIndex, "resultsList.count:", resultsList.count);
                
                if (root.selectedIndex >= 0 && root.selectedIndex < resultsList.count) {
                    let selectedSession = root.filteredSessions[root.selectedIndex];
                    console.log("DEBUG: Selected session:", selectedSession);
                    if (selectedSession) {
                        if (selectedSession.isCreateSpecificButton) {
                            console.log("DEBUG: Creating specific session:", selectedSession.sessionNameToCreate);
                            root.createTmuxSession(selectedSession.sessionNameToCreate);
                        } else if (selectedSession.isCreateButton) {
                            console.log("DEBUG: Creating new session via create button");
                            root.createTmuxSession();
                        } else {
                            console.log("DEBUG: Attaching to existing session:", selectedSession.name);
                            root.attachToSession(selectedSession.name);
                        }
                    }
                } else {
                    console.log("DEBUG: No action taken - selectedIndex:", root.selectedIndex, "count:", resultsList.count);
                }
            }

            onEscapePressed: {
                root.itemSelected();
            }

            onDownPressed: {
                if (resultsList.count > 0) {
                    if (root.selectedIndex === -1) {
                        root.selectedIndex = 0;
                        resultsList.currentIndex = 0;
                    } else if (root.selectedIndex < resultsList.count - 1) {
                        root.selectedIndex++;
                        resultsList.currentIndex = root.selectedIndex;
                    }
                }
            }

            onUpPressed: {
                if (root.selectedIndex > 0) {
                    root.selectedIndex--;
                    resultsList.currentIndex = root.selectedIndex;
                } else if (root.selectedIndex === 0 && root.searchText.length === 0) {
                    root.selectedIndex = -1;
                    resultsList.currentIndex = -1;
                }
            }

            onPageDownPressed: {
                if (resultsList.count > 0) {
                    let visibleItems = Math.floor(resultsList.height / 48);
                    let newIndex = Math.min(root.selectedIndex + visibleItems, resultsList.count - 1);
                    if (root.selectedIndex === -1) {
                        newIndex = Math.min(visibleItems - 1, resultsList.count - 1);
                    }
                    root.selectedIndex = newIndex;
                    resultsList.currentIndex = root.selectedIndex;
                }
            }

            onPageUpPressed: {
                if (resultsList.count > 0) {
                    let visibleItems = Math.floor(resultsList.height / 48);
                    let newIndex = Math.max(root.selectedIndex - visibleItems, 0);
                    if (root.selectedIndex === -1) {
                        newIndex = Math.max(resultsList.count - visibleItems, 0);
                    }
                    root.selectedIndex = newIndex;
                    resultsList.currentIndex = root.selectedIndex;
                }
            }

            onHomePressed: {
                if (resultsList.count > 0) {
                    root.selectedIndex = 0;
                    resultsList.currentIndex = 0;
                }
            }

            onEndPressed: {
                if (resultsList.count > 0) {
                    root.selectedIndex = resultsList.count - 1;
                    resultsList.currentIndex = root.selectedIndex;
                }
            }
        }

        // Results list
        ListView {
            id: resultsList
            Layout.fillWidth: true
            Layout.preferredHeight: 5 * 48
            visible: true
            clip: true

            model: root.filteredSessions
            currentIndex: root.selectedIndex

            // Sync currentIndex with selectedIndex
            onCurrentIndexChanged: {
                if (currentIndex !== root.selectedIndex) {
                    root.selectedIndex = currentIndex;
                }
            }

            delegate: Rectangle {
                required property var modelData
                required property int index

                width: resultsList.width
                height: 48
                color: "transparent"
                radius: 16

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true

                    onEntered: {
                        root.selectedIndex = index;
                        resultsList.currentIndex = index;
                    }
                    onClicked: {
                        if (modelData.isCreateSpecificButton) {
                            root.createTmuxSession(modelData.sessionNameToCreate);
                        } else if (modelData.isCreateButton) {
                            root.createTmuxSession();
                        } else {
                            root.attachToSession(modelData.name);
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 12

                    // Icono
                    Rectangle {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        color: modelData.isCreateButton ? Colors.adapter.primary : Colors.adapter.surface
                        radius: 6

                        Text {
                            anchors.centerIn: parent
                            text: ""  // Icono de terminal
                            color: modelData.isCreateButton ? Colors.background : Colors.adapter.overSurface
                            font.family: Icons.font
                            font.pixelSize: 16
                        }
                    }

                    // Texto
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: modelData.name
                            color: Colors.adapter.overBackground
                            font.family: Config.theme.font
                            font.pixelSize: Config.theme.fontSize
                            font.weight: modelData.isCreateButton ? Font.Medium : Font.Bold
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.isCreateButton ? "Create a new tmux session" : "Tmux session"
                            color: Colors.adapter.overBackground
                            opacity: 0.7
                            font.family: Config.theme.font
                            font.pixelSize: Config.theme.fontSize - 2
                            elide: Text.ElideRight
                            visible: !modelData.isCreateButton || root.searchText.length === 0
                        }
                    }
                }
            }

            highlight: Rectangle {
                color: Colors.adapter.primary
                opacity: 0.2
                radius: Config.roundness > 0 ? Config.roundness + 4 : 0
                visible: root.selectedIndex >= 0
            }

            highlightMoveDuration: Config.animDuration / 2
            highlightMoveVelocity: -1
        }
    }

    Component.onCompleted: {
        // Cargar sesiones de tmux al inicializar
        refreshTmuxSessions();
        Qt.callLater(() => {
            focusSearchInput();
        });
    }
}
