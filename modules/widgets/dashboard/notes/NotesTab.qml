import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.modules.theme
import qs.modules.components
import qs.modules.globals
import qs.modules.services
import qs.config
import "notes_utils.js" as NotesUtils

Item {
    id: root
    focus: true

    // Prefix support
    property string prefixIcon: ""
    signal backspaceOnEmpty

    property int leftPanelWidth: 0

    // Notes directory configuration
    property string notesDir: (Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")) + "/ambxst-notes"
    property string indexPath: notesDir + "/index.json"
    property string notesPath: notesDir + "/notes"

    // Search and selection state
    property string searchText: ""
    property bool showResults: searchText.length > 0
    property int selectedIndex: -1
    property var allNotes: []
    property var filteredNotes: []

    // List model
    ListModel {
        id: notesModel
    }

    // Delete mode state
    property bool deleteMode: false
    property string noteToDelete: ""
    property int originalSelectedIndex: -1
    property int deleteButtonIndex: 0

    // Rename mode state
    property bool renameMode: false
    property string noteToRename: ""
    property string newNoteName: ""
    property int renameSelectedIndex: -1
    property int renameButtonIndex: 0
    property string pendingRenamedNote: ""

    // Options menu state (expandable list)
    property int expandedItemIndex: -1
    property int selectedOptionIndex: 0
    property bool keyboardNavigation: false

    // Current note content for editor
    property string currentNoteId: ""
    property string currentNoteContent: ""
    property string currentNoteTitle: ""
    property bool loadingNote: false
    property bool editorDirty: false

    // Debounce timer for auto-save
    Timer {
        id: saveDebounceTimer
        interval: 500
        repeat: false
        onTriggered: {
            if (currentNoteId && editorDirty) {
                saveCurrentNote();
            }
        }
    }

    Keys.onEscapePressed: {
        if (root.deleteMode) {
            root.cancelDeleteMode();
        } else if (root.renameMode) {
            root.cancelRenameMode();
        } else {
            Visibilities.setActiveModule("");
        }
    }

    onExpandedItemIndexChanged: {}

    function adjustScrollForExpandedItem(index) {
        if (index < 0 || index >= notesModel.count)
            return;

        var itemY = 0;
        for (var i = 0; i < index; i++) {
            itemY += 48;
        }

        // 3 options: Edit, Rename, Delete
        var listHeight = 36 * 3;
        var expandedHeight = 48 + 4 + listHeight + 8;

        var maxContentY = Math.max(0, resultsList.contentHeight - resultsList.height);
        var viewportTop = resultsList.contentY;
        var viewportBottom = viewportTop + resultsList.height;
        var itemBottom = itemY + expandedHeight;

        if (itemY < viewportTop) {
            resultsList.contentY = itemY;
        } else if (itemBottom > viewportBottom) {
            resultsList.contentY = Math.min(itemBottom - resultsList.height, maxContentY);
        }
    }

    onSelectedIndexChanged: {
        if (selectedIndex === -1 && resultsList.count > 0) {
            resultsList.positionViewAtIndex(0, ListView.Beginning);
        }

        if (expandedItemIndex >= 0 && selectedIndex !== expandedItemIndex) {
            expandedItemIndex = -1;
            selectedOptionIndex = 0;
            keyboardNavigation = false;
        }

        // Load note content when selection changes
        if (selectedIndex >= 0 && selectedIndex < filteredNotes.length) {
            let note = filteredNotes[selectedIndex];
            if (note && !note.isCreateButton) {
                loadNoteContent(note.id);
            } else {
                currentNoteId = "";
                currentNoteContent = "";
                currentNoteTitle = "";
            }
        } else {
            currentNoteId = "";
            currentNoteContent = "";
            currentNoteTitle = "";
        }
    }

    onSearchTextChanged: {
        updateFilteredNotes();
    }

    function clearSearch() {
        searchText = "";
        selectedIndex = -1;
        searchInput.focusInput();
        updateFilteredNotes();
    }

    function focusSearchInput() {
        searchInput.focusInput();
    }

    function cancelDeleteModeFromExternal() {
        if (deleteMode) {
            cancelDeleteMode();
        }
        if (renameMode) {
            cancelRenameMode();
        }
    }

    function updateFilteredNotes() {
        var newFilteredNotes = [];

        var createButtonText = "Create new note";
        var isCreateSpecific = false;
        var noteNameToCreate = "";

        if (searchText.length === 0) {
            newFilteredNotes = allNotes.slice();
        } else {
            newFilteredNotes = NotesUtils.filterNotes(allNotes, searchText);

            let exactMatch = allNotes.find(function(note) {
                return note.title.toLowerCase() === searchText.toLowerCase();
            });

            if (!exactMatch && searchText.length > 0) {
                createButtonText = `Create note "${searchText}"`;
                isCreateSpecific = true;
                noteNameToCreate = searchText;
            }
        }

        if (!deleteMode && !renameMode) {
            newFilteredNotes.unshift({
                id: "__create__",
                title: createButtonText,
                isCreateButton: true,
                isCreateSpecificButton: isCreateSpecific,
                noteNameToCreate: noteNameToCreate,
                icon: "plus"
            });
        }

        filteredNotes = newFilteredNotes;
        resultsList.enableScrollAnimation = false;
        resultsList.contentY = 0;

        notesModel.clear();
        for (var i = 0; i < newFilteredNotes.length; i++) {
            var note = newFilteredNotes[i];
            notesModel.append({
                noteId: note.id,
                noteData: note
            });
        }

        Qt.callLater(() => {
            resultsList.enableScrollAnimation = true;
        });

        if (!deleteMode && !renameMode) {
            if (searchText.length > 0 && newFilteredNotes.length > 0) {
                selectedIndex = 0;
                resultsList.currentIndex = 0;
            } else if (searchText.length === 0) {
                selectedIndex = -1;
                resultsList.currentIndex = -1;
            }
        }

        if (pendingRenamedNote !== "") {
            for (let i = 0; i < newFilteredNotes.length; i++) {
                if (newFilteredNotes[i].id === pendingRenamedNote) {
                    selectedIndex = i;
                    resultsList.currentIndex = i;
                    pendingRenamedNote = "";
                    break;
                }
            }
            if (pendingRenamedNote !== "") {
                pendingRenamedNote = "";
            }
        }
    }

    function enterDeleteMode(noteId) {
        originalSelectedIndex = selectedIndex;
        deleteMode = true;
        noteToDelete = noteId;
        deleteButtonIndex = 0;
        root.forceActiveFocus();
    }

    function cancelDeleteMode() {
        deleteMode = false;
        noteToDelete = "";
        deleteButtonIndex = 0;
        searchInput.focusInput();
        updateFilteredNotes();
        selectedIndex = originalSelectedIndex;
        resultsList.currentIndex = originalSelectedIndex;
        originalSelectedIndex = -1;
    }

    function confirmDeleteNote() {
        if (noteToDelete) {
            deleteNoteProcess.command = ["rm", "-f", notesPath + "/" + noteToDelete + ".md"];
            deleteNoteProcess.running = true;
        }
        cancelDeleteMode();
    }

    function enterRenameMode(noteId) {
        renameSelectedIndex = selectedIndex;
        renameMode = true;
        noteToRename = noteId;
        
        // Find current title
        for (var i = 0; i < allNotes.length; i++) {
            if (allNotes[i].id === noteId) {
                newNoteName = allNotes[i].title;
                break;
            }
        }
        
        renameButtonIndex = 1;
        root.forceActiveFocus();
    }

    function cancelRenameMode() {
        renameMode = false;
        noteToRename = "";
        newNoteName = "";
        renameButtonIndex = 1;
        if (pendingRenamedNote === "") {
            searchInput.focusInput();
            updateFilteredNotes();
            selectedIndex = renameSelectedIndex;
            resultsList.currentIndex = renameSelectedIndex;
        } else {
            searchInput.focusInput();
        }
        renameSelectedIndex = -1;
    }

    function confirmRenameNote() {
        if (newNoteName.trim() !== "" && noteToRename) {
            pendingRenamedNote = noteToRename;
            updateNoteTitle(noteToRename, newNoteName.trim());
        }
        cancelRenameMode();
    }

    function createNewNote(title) {
        var noteId = NotesUtils.generateUUID();
        var noteTitle = title || "Untitled Note";
        
        // Create the note file
        var initialContent = "# " + noteTitle + "\n\n";
        createNoteProcess.noteId = noteId;
        createNoteProcess.noteTitle = noteTitle;
        createNoteProcess.command = ["sh", "-c", 
            "mkdir -p '" + notesPath + "' && printf '%s' '" + initialContent.replace(/'/g, "'\\''") + "' > '" + notesPath + "/" + noteId + ".md'"
        ];
        createNoteProcess.running = true;
    }

    function loadNoteContent(noteId) {
        if (!noteId || noteId === "__create__") return;
        
        // Save current note before loading new one
        if (currentNoteId && editorDirty) {
            saveCurrentNote();
        }
        
        loadingNote = true;
        currentNoteId = noteId;
        readNoteProcess.command = ["cat", notesPath + "/" + noteId + ".md"];
        readNoteProcess.running = true;
    }

    function saveCurrentNote() {
        if (!currentNoteId || currentNoteId === "__create__") return;
        
        var content = noteEditor.text;
        saveNoteProcess.command = ["sh", "-c",
            "printf '%s' '" + content.replace(/'/g, "'\\''") + "' > '" + notesPath + "/" + currentNoteId + ".md'"
        ];
        saveNoteProcess.running = true;
        editorDirty = false;
        
        // Update modified timestamp
        updateNoteModified(currentNoteId);
    }

    function updateNoteTitle(noteId, newTitle) {
        // Read index, update title, save
        readIndexForUpdateProcess.noteId = noteId;
        readIndexForUpdateProcess.newTitle = newTitle;
        readIndexForUpdateProcess.command = ["cat", indexPath];
        readIndexForUpdateProcess.running = true;
    }

    function updateNoteModified(noteId) {
        readIndexForModifiedProcess.noteId = noteId;
        readIndexForModifiedProcess.command = ["cat", indexPath];
        readIndexForModifiedProcess.running = true;
    }

    function refreshNotes() {
        readIndexProcess.running = true;
    }

    function openNoteInEditor(noteId) {
        // Select the note and focus editor
        for (var i = 0; i < filteredNotes.length; i++) {
            if (filteredNotes[i].id === noteId) {
                selectedIndex = i;
                resultsList.currentIndex = i;
                break;
            }
        }
        Qt.callLater(() => {
            noteEditor.forceActiveFocus();
        });
    }

    // Move note up/down in order
    function moveNoteUp() {
        if (selectedIndex <= 1) return; // Can't move create button or first note
        
        let note = filteredNotes[selectedIndex];
        if (note.isCreateButton) return;
        
        // Find in allNotes and swap
        let noteIdx = -1;
        for (let i = 0; i < allNotes.length; i++) {
            if (allNotes[i].id === note.id) {
                noteIdx = i;
                break;
            }
        }
        
        if (noteIdx > 0) {
            allNotes = NotesUtils.moveArrayItem(allNotes, noteIdx, noteIdx - 1);
            saveNotesOrder();
            updateFilteredNotes();
            selectedIndex = selectedIndex - 1;
            resultsList.currentIndex = selectedIndex;
        }
    }

    function moveNoteDown() {
        if (selectedIndex < 1 || selectedIndex >= filteredNotes.length - 1) return;
        
        let note = filteredNotes[selectedIndex];
        if (note.isCreateButton) return;
        
        let noteIdx = -1;
        for (let i = 0; i < allNotes.length; i++) {
            if (allNotes[i].id === note.id) {
                noteIdx = i;
                break;
            }
        }
        
        if (noteIdx >= 0 && noteIdx < allNotes.length - 1) {
            allNotes = NotesUtils.moveArrayItem(allNotes, noteIdx, noteIdx + 1);
            saveNotesOrder();
            updateFilteredNotes();
            selectedIndex = selectedIndex + 1;
            resultsList.currentIndex = selectedIndex;
        }
    }

    function saveNotesOrder() {
        var indexData = {
            order: allNotes.map(n => n.id),
            notes: {}
        };
        for (var i = 0; i < allNotes.length; i++) {
            var note = allNotes[i];
            indexData.notes[note.id] = {
                title: note.title,
                created: note.created,
                modified: note.modified
            };
        }
        var jsonContent = NotesUtils.serializeIndex(indexData);
        saveIndexProcess.command = ["sh", "-c",
            "printf '%s' '" + jsonContent.replace(/'/g, "'\\''") + "' > '" + indexPath + "'"
        ];
        saveIndexProcess.running = true;
    }

    Component.onCompleted: {
        initDirProcess.running = true;
    }

    // --- Processes ---

    // Initialize directories
    Process {
        id: initDirProcess
        command: ["sh", "-c", "mkdir -p '" + notesPath + "' && touch '" + indexPath + "'"]
        
        onExited: (code) => {
            refreshNotes();
        }
    }

    // Read index.json
    Process {
        id: readIndexProcess
        command: ["cat", indexPath]
        stdout: SplitParser {
            onRead: data => readIndexProcess.stdoutData += data + "\n"
        }
        property string stdoutData: ""
        
        onExited: (code) => {
            var indexData = NotesUtils.parseIndex(stdoutData.trim());
            stdoutData = "";
            
            var loadedNotes = [];
            for (var i = 0; i < indexData.order.length; i++) {
                var noteId = indexData.order[i];
                var noteMeta = indexData.notes[noteId];
                if (noteMeta) {
                    loadedNotes.push({
                        id: noteId,
                        title: noteMeta.title || "Untitled",
                        created: noteMeta.created || "",
                        modified: noteMeta.modified || "",
                        isCreateButton: false
                    });
                }
            }
            
            allNotes = loadedNotes;
            updateFilteredNotes();
        }
    }

    // Create note
    Process {
        id: createNoteProcess
        property string noteId: ""
        property string noteTitle: ""
        
        onExited: (code) => {
            if (code === 0) {
                // Add to allNotes and save index
                var newNote = {
                    id: noteId,
                    title: noteTitle,
                    created: NotesUtils.getCurrentTimestamp(),
                    modified: NotesUtils.getCurrentTimestamp(),
                    isCreateButton: false
                };
                allNotes.unshift(newNote);
                saveNotesOrder();
                updateFilteredNotes();
                
                // Select the new note
                pendingRenamedNote = noteId;
                updateFilteredNotes();
                
                // Focus the editor
                Qt.callLater(() => {
                    openNoteInEditor(noteId);
                });
            }
            noteId = "";
            noteTitle = "";
        }
    }

    // Delete note and update index
    Process {
        id: deleteNoteProcess
        
        onExited: (code) => {
            if (code === 0) {
                // Remove from allNotes
                allNotes = allNotes.filter(n => n.id !== noteToDelete);
                saveNotesOrder();
                
                if (currentNoteId === noteToDelete) {
                    currentNoteId = "";
                    currentNoteContent = "";
                    currentNoteTitle = "";
                }
                
                updateFilteredNotes();
            }
        }
    }

    // Read note content
    Process {
        id: readNoteProcess
        stdout: SplitParser {
            onRead: data => readNoteProcess.stdoutData += data + "\n"
        }
        property string stdoutData: ""
        
        onExited: (code) => {
            if (code === 0) {
                // Remove trailing newline added by parser
                currentNoteContent = stdoutData.replace(/\n$/, '');
                
                // Find title
                for (var i = 0; i < allNotes.length; i++) {
                    if (allNotes[i].id === currentNoteId) {
                        currentNoteTitle = allNotes[i].title;
                        break;
                    }
                }
            } else {
                currentNoteContent = "";
                currentNoteTitle = "";
            }
            stdoutData = "";
            editorDirty = false;
            loadingNote = false;
        }
    }

    // Save note content
    Process {
        id: saveNoteProcess
        onExited: (code) => {}
    }

    // Save index
    Process {
        id: saveIndexProcess
        onExited: (code) => {}
    }

    // Read index for title update
    Process {
        id: readIndexForUpdateProcess
        property string noteId: ""
        property string newTitle: ""
        stdout: SplitParser {
            onRead: data => readIndexForUpdateProcess.stdoutData += data + "\n"
        }
        property string stdoutData: ""
        
        onExited: (code) => {
            var indexData = NotesUtils.parseIndex(stdoutData.trim());
            stdoutData = "";
            
            if (indexData.notes[noteId]) {
                indexData.notes[noteId].title = newTitle;
                indexData.notes[noteId].modified = NotesUtils.getCurrentTimestamp();
            }
            
            // Update local allNotes
            for (var i = 0; i < allNotes.length; i++) {
                if (allNotes[i].id === noteId) {
                    allNotes[i].title = newTitle;
                    allNotes[i].modified = NotesUtils.getCurrentTimestamp();
                    break;
                }
            }
            
            var jsonContent = NotesUtils.serializeIndex(indexData);
            saveIndexProcess.command = ["sh", "-c",
                "printf '%s' '" + jsonContent.replace(/'/g, "'\\''") + "' > '" + indexPath + "'"
            ];
            saveIndexProcess.running = true;
            
            updateFilteredNotes();
            noteId = "";
            newTitle = "";
        }
    }

    // Read index for modified timestamp update
    Process {
        id: readIndexForModifiedProcess
        property string noteId: ""
        stdout: SplitParser {
            onRead: data => readIndexForModifiedProcess.stdoutData += data + "\n"
        }
        property string stdoutData: ""
        
        onExited: (code) => {
            var indexData = NotesUtils.parseIndex(stdoutData.trim());
            stdoutData = "";
            
            if (indexData.notes[noteId]) {
                indexData.notes[noteId].modified = NotesUtils.getCurrentTimestamp();
            }
            
            var jsonContent = NotesUtils.serializeIndex(indexData);
            saveIndexProcess.command = ["sh", "-c",
                "printf '%s' '" + jsonContent.replace(/'/g, "'\\''") + "' > '" + indexPath + "'"
            ];
            saveIndexProcess.running = true;
            noteId = "";
        }
    }

    implicitWidth: 400
    implicitHeight: 7 * 48 + 56

    RowLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: 8

        // Left panel: Notes list
        Item {
            Layout.preferredWidth: root.leftPanelWidth
            Layout.fillHeight: true

            // Search input
            SearchInput {
                id: searchInput
                width: parent.width
                height: 48
                anchors.top: parent.top
                text: root.searchText
                placeholderText: "Search notes..."
                prefixIcon: root.prefixIcon
                handleTabNavigation: true

                onSearchTextChanged: text => {
                    root.searchText = text;
                }

                onBackspaceOnEmpty: {
                    root.backspaceOnEmpty();
                }

                onAccepted: {
                    if (root.deleteMode) {
                        if (root.deleteButtonIndex === 1) {
                            root.confirmDeleteNote();
                        } else {
                            root.cancelDeleteMode();
                        }
                        return;
                    }

                    if (root.renameMode) {
                        if (root.renameButtonIndex === 1) {
                            root.confirmRenameNote();
                        } else {
                            root.cancelRenameMode();
                        }
                        return;
                    }

                    if (root.expandedItemIndex >= 0) {
                        let note = filteredNotes[root.expandedItemIndex];
                        if (note && !note.isCreateButton) {
                            let options = [
                                function() { openNoteInEditor(note.id); },
                                function() { enterRenameMode(note.id); },
                                function() { enterDeleteMode(note.id); }
                            ];
                            if (root.selectedOptionIndex >= 0 && root.selectedOptionIndex < options.length) {
                                options[root.selectedOptionIndex]();
                            }
                        }
                        root.expandedItemIndex = -1;
                        root.selectedOptionIndex = 0;
                        return;
                    }

                    if (root.selectedIndex >= 0 && root.selectedIndex < filteredNotes.length) {
                        let note = filteredNotes[root.selectedIndex];
                        if (note.isCreateButton || note.isCreateSpecificButton) {
                            createNewNote(note.noteNameToCreate || "");
                        } else {
                            openNoteInEditor(note.id);
                        }
                    }
                }

                onShiftAccepted: {
                    if (root.selectedIndex >= 0 && root.selectedIndex < filteredNotes.length) {
                        let note = filteredNotes[root.selectedIndex];
                        if (!note.isCreateButton) {
                            if (root.expandedItemIndex === root.selectedIndex) {
                                root.expandedItemIndex = -1;
                                root.selectedOptionIndex = 0;
                                root.keyboardNavigation = false;
                            } else {
                                root.expandedItemIndex = root.selectedIndex;
                                root.selectedOptionIndex = 0;
                                root.keyboardNavigation = true;
                            }
                        }
                    }
                }

                onEscapePressed: {
                    if (root.deleteMode) {
                        root.cancelDeleteMode();
                    } else if (root.renameMode) {
                        root.cancelRenameMode();
                    } else if (root.expandedItemIndex >= 0) {
                        root.expandedItemIndex = -1;
                        root.selectedOptionIndex = 0;
                        root.keyboardNavigation = false;
                    } else {
                        Visibilities.setActiveModule("");
                    }
                }

                onDownPressed: {
                    if (root.deleteMode) {
                        return;
                    }
                    if (root.renameMode) {
                        return;
                    }
                    if (root.expandedItemIndex >= 0) {
                        if (root.selectedOptionIndex < 2) {
                            root.selectedOptionIndex++;
                            root.keyboardNavigation = true;
                        }
                    } else if (resultsList.count > 0) {
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
                    if (root.deleteMode) {
                        return;
                    }
                    if (root.renameMode) {
                        return;
                    }
                    if (root.expandedItemIndex >= 0) {
                        if (root.selectedOptionIndex > 0) {
                            root.selectedOptionIndex--;
                            root.keyboardNavigation = true;
                        }
                    } else if (root.selectedIndex > 0) {
                        root.selectedIndex--;
                        resultsList.currentIndex = root.selectedIndex;
                    } else if (root.selectedIndex === 0 && root.searchText.length === 0) {
                        root.selectedIndex = -1;
                        resultsList.currentIndex = -1;
                    }
                }

                onCtrlUpPressed: {
                    root.moveNoteUp();
                }

                onCtrlDownPressed: {
                    root.moveNoteDown();
                }

                onLeftPressed: {
                    if (root.deleteMode) {
                        root.deleteButtonIndex = 0;
                    }
                    if (root.renameMode) {
                        root.renameButtonIndex = 0;
                    }
                }

                onRightPressed: {
                    if (root.deleteMode) {
                        root.deleteButtonIndex = 1;
                    }
                    if (root.renameMode) {
                        root.renameButtonIndex = 1;
                    }
                }

                onTabPressed: {
                    // Focus editor when pressing Tab
                    if (currentNoteId) {
                        noteEditor.forceActiveFocus();
                    }
                }
            }

            // Rename input (shown in rename mode)
            Rectangle {
                id: renameContainer
                width: parent.width
                height: renameMode ? 48 : 0
                anchors.top: searchInput.bottom
                anchors.topMargin: renameMode ? 4 : 0
                color: "transparent"
                visible: renameMode
                clip: true

                Behavior on height {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    TextField {
                        id: renameInput
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        text: newNoteName
                        placeholderText: "New name..."
                        font.family: Config.theme.font
                        font.pixelSize: Config.theme.fontSize
                        color: Colors.overSurface
                        background: StyledRect {
                            variant: "pane"
                            radius: Styling.radius(-4)
                        }

                        onTextChanged: {
                            newNoteName = text;
                        }

                        Keys.onReturnPressed: {
                            if (renameButtonIndex === 1) {
                                confirmRenameNote();
                            } else {
                                cancelRenameMode();
                            }
                        }

                        Keys.onEscapePressed: {
                            cancelRenameMode();
                        }
                    }

                    Row {
                        spacing: 4

                        Rectangle {
                            width: 32
                            height: 32
                            color: "transparent"
                            radius: 6

                            property bool isHighlighted: renameButtonIndex === 0

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: cancelRenameMode()
                                onEntered: renameButtonIndex = 0
                            }

                            StyledRect {
                                anchors.fill: parent
                                variant: parent.isHighlighted ? "secondary" : "transparent"
                                radius: Styling.radius(-4)
                            }

                            Text {
                                anchors.centerIn: parent
                                text: Icons.cancel
                                color: parent.isHighlighted ? Config.resolveColor(Config.theme.srSecondary.itemColor) : Colors.overSurface
                                font.pixelSize: 14
                                font.family: Icons.font
                                textFormat: Text.RichText
                            }
                        }

                        Rectangle {
                            width: 32
                            height: 32
                            color: "transparent"
                            radius: 6

                            property bool isHighlighted: renameButtonIndex === 1

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: confirmRenameNote()
                                onEntered: renameButtonIndex = 1
                            }

                            StyledRect {
                                anchors.fill: parent
                                variant: parent.isHighlighted ? "secondary" : "transparent"
                                radius: Styling.radius(-4)
                            }

                            Text {
                                anchors.centerIn: parent
                                text: Icons.accept
                                color: parent.isHighlighted ? Config.resolveColor(Config.theme.srSecondary.itemColor) : Colors.overSurface
                                font.pixelSize: 14
                                font.family: Icons.font
                                textFormat: Text.RichText
                            }
                        }
                    }
                }
            }

            // Results list
            ListView {
                id: resultsList
                width: parent.width
                anchors.top: renameContainer.bottom
                anchors.bottom: parent.bottom
                anchors.topMargin: 8
                clip: true
                model: notesModel
                currentIndex: root.selectedIndex
                spacing: 0
                interactive: !root.deleteMode && !root.renameMode && root.expandedItemIndex === -1

                property bool enableScrollAnimation: true

                Behavior on contentY {
                    enabled: resultsList.enableScrollAnimation && Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration / 2
                        easing.type: Easing.OutCubic
                    }
                }

                onCurrentIndexChanged: {
                    if (currentIndex >= 0 && currentIndex < count) {
                        positionViewAtIndex(currentIndex, ListView.Contain);
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    active: true
                }

                highlight: Item {
                    width: resultsList.width
                    height: {
                        let baseHeight = 48;
                        if (resultsList.currentIndex === root.expandedItemIndex && !root.deleteMode && !root.renameMode) {
                            var listHeight = 36 * 3; // 3 options
                            return baseHeight + 4 + listHeight + 8;
                        }
                        return baseHeight;
                    }

                    y: {
                        var yPos = 0;
                        for (var i = 0; i < resultsList.currentIndex && i < notesModel.count; i++) {
                            var itemHeight = 48;
                            if (i === root.expandedItemIndex && !root.deleteMode && !root.renameMode) {
                                var listHeight = 36 * 3;
                                itemHeight = 48 + 4 + listHeight + 8;
                            }
                            yPos += itemHeight;
                        }
                        return yPos;
                    }

                    Behavior on y {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration / 2
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on height {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutQuart
                        }
                    }

                    onHeightChanged: {
                        if (root.expandedItemIndex >= 0 && height > 48) {
                            Qt.callLater(() => {
                                root.adjustScrollForExpandedItem(root.expandedItemIndex);
                            });
                        }
                    }

                    StyledRect {
                        anchors.fill: parent
                        variant: {
                            if (root.deleteMode) {
                                return "error";
                            } else if (root.renameMode) {
                                return "secondary";
                            } else if (root.expandedItemIndex >= 0 && root.selectedIndex === root.expandedItemIndex) {
                                return "pane";
                            } else {
                                return "primary";
                            }
                        }
                        radius: Styling.radius(4)
                        visible: root.selectedIndex >= 0

                        Behavior on color {
                            enabled: Config.animDuration > 0
                            ColorAnimation {
                                duration: Config.animDuration / 2
                                easing.type: Easing.OutQuart
                            }
                        }
                    }
                }

                highlightFollowsCurrentItem: false

                delegate: Rectangle {
                    required property string noteId
                    required property var noteData
                    required property int index

                    property var modelData: noteData

                    width: resultsList.width
                    height: {
                        let baseHeight = 48;
                        if (index === root.expandedItemIndex && !isInDeleteMode && !isInRenameMode) {
                            var listHeight = 36 * 3;
                            return baseHeight + 4 + listHeight + 8;
                        }
                        return baseHeight;
                    }
                    color: "transparent"
                    radius: 16

                    Behavior on height {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutQuart
                        }
                    }

                    property bool isInDeleteMode: root.deleteMode && modelData.id === root.noteToDelete
                    property bool isInRenameMode: root.renameMode && modelData.id === root.noteToRename
                    property bool isSelected: root.selectedIndex === index
                    property bool isExpanded: index === root.expandedItemIndex
                    property color textColor: {
                        if (isInDeleteMode) {
                            return Config.resolveColor(Config.theme.srError.itemColor);
                        } else if (isExpanded) {
                            return Config.resolveColor(Config.theme.srPane.itemColor);
                        } else if (isSelected) {
                            return Config.resolveColor(Config.theme.srPrimary.itemColor);
                        } else {
                            return Colors.overSurface;
                        }
                    }
                    property string displayText: {
                        if (isInDeleteMode) {
                            return "Delete \"" + modelData.title.substring(0, 20) + (modelData.title.length > 20 ? '...' : '') + "\"?";
                        }
                        return modelData.title || "Untitled";
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        height: isExpanded ? 48 : parent.height
                        hoverEnabled: true
                        enabled: !root.deleteMode && !root.renameMode
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        onEntered: {
                            if (!root.deleteMode && root.expandedItemIndex === -1) {
                                root.selectedIndex = index;
                                resultsList.currentIndex = index;
                            }
                        }

                        onClicked: mouse => {
                            if (mouse.button === Qt.LeftButton && !isInDeleteMode) {
                                if (root.deleteMode && modelData.id !== root.noteToDelete) {
                                    root.cancelDeleteMode();
                                    return;
                                }

                                if (!root.deleteMode && !isExpanded) {
                                    if (modelData.isCreateButton || modelData.isCreateSpecificButton) {
                                        createNewNote(modelData.noteNameToCreate || "");
                                    } else {
                                        openNoteInEditor(modelData.id);
                                    }
                                }
                            } else if (mouse.button === Qt.RightButton) {
                                if (root.deleteMode) {
                                    root.cancelDeleteMode();
                                    return;
                                }

                                if (modelData.isCreateButton) return;

                                if (root.expandedItemIndex === index) {
                                    root.expandedItemIndex = -1;
                                    root.selectedOptionIndex = 0;
                                    root.keyboardNavigation = false;
                                    root.selectedIndex = index;
                                    resultsList.currentIndex = index;
                                } else {
                                    root.expandedItemIndex = index;
                                    root.selectedIndex = index;
                                    resultsList.currentIndex = index;
                                    root.selectedOptionIndex = 0;
                                    root.keyboardNavigation = false;
                                }
                            }
                        }

                        // Delete buttons
                        Rectangle {
                            id: actionContainer
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.rightMargin: 8
                            width: 68
                            height: 32
                            color: "transparent"
                            opacity: isInDeleteMode ? 1.0 : 0.0
                            visible: opacity > 0

                            transform: Translate {
                                x: isInDeleteMode ? 0 : 80

                                Behavior on x {
                                    enabled: Config.animDuration > 0
                                    NumberAnimation {
                                        duration: Config.animDuration
                                        easing.type: Easing.OutQuart
                                    }
                                }
                            }

                            Behavior on opacity {
                                enabled: Config.animDuration > 0
                                NumberAnimation {
                                    duration: Config.animDuration / 2
                                    easing.type: Easing.OutQuart
                                }
                            }

                            StyledRect {
                                id: deleteHighlight
                                variant: "overerror"
                                radius: Styling.radius(-4)
                                visible: isInDeleteMode
                                z: 0

                                property real activeButtonMargin: 2
                                property real idx1X: root.deleteButtonIndex
                                property real idx2X: root.deleteButtonIndex

                                x: {
                                    let minX = Math.min(idx1X, idx2X) * 36 + activeButtonMargin;
                                    return minX;
                                }

                                y: activeButtonMargin

                                width: {
                                    let stretchX = Math.abs(idx1X - idx2X) * 36 + 32 - activeButtonMargin * 2;
                                    return stretchX;
                                }

                                height: 32 - activeButtonMargin * 2

                                Behavior on idx1X {
                                    enabled: Config.animDuration > 0
                                    NumberAnimation {
                                        duration: Config.animDuration / 3
                                        easing.type: Easing.OutSine
                                    }
                                }
                                Behavior on idx2X {
                                    enabled: Config.animDuration > 0
                                    NumberAnimation {
                                        duration: Config.animDuration
                                        easing.type: Easing.OutSine
                                    }
                                }
                            }

                            Row {
                                id: actionButtons
                                anchors.fill: parent
                                spacing: 4

                                Rectangle {
                                    width: 32
                                    height: 32
                                    color: "transparent"
                                    radius: 6
                                    z: 1

                                    property bool isHighlighted: root.deleteButtonIndex === 0

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: root.cancelDeleteMode()
                                        onEntered: root.deleteButtonIndex = 0
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: Icons.cancel
                                        color: parent.isHighlighted ? Colors.overErrorContainer : Colors.overError
                                        font.pixelSize: 14
                                        font.family: Icons.font
                                        textFormat: Text.RichText

                                        Behavior on color {
                                            enabled: Config.animDuration > 0
                                            ColorAnimation {
                                                duration: Config.animDuration / 2
                                                easing.type: Easing.OutQuart
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    width: 32
                                    height: 32
                                    color: "transparent"
                                    radius: 6
                                    z: 1

                                    property bool isHighlighted: root.deleteButtonIndex === 1

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: root.confirmDeleteNote()
                                        onEntered: root.deleteButtonIndex = 1
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: Icons.accept
                                        color: parent.isHighlighted ? Colors.overErrorContainer : Colors.overError
                                        font.pixelSize: 14
                                        font.family: Icons.font
                                        textFormat: Text.RichText

                                        Behavior on color {
                                            enabled: Config.animDuration > 0
                                            ColorAnimation {
                                                duration: Config.animDuration / 2
                                                easing.type: Easing.OutQuart
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Item content
                    RowLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        height: 48
                        anchors.margins: 12
                        spacing: 8

                        Text {
                            text: modelData.isCreateButton ? Icons.plus : Icons.file
                            font.family: Icons.font
                            font.pixelSize: 16
                            color: textColor
                            textFormat: Text.RichText

                            Behavior on color {
                                enabled: Config.animDuration > 0
                                ColorAnimation {
                                    duration: Config.animDuration / 2
                                    easing.type: Easing.OutQuart
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: displayText
                                font.family: Config.theme.font
                                font.pixelSize: Config.theme.fontSize
                                font.weight: isSelected ? Font.Bold : Font.Normal
                                color: textColor
                                elide: Text.ElideRight
                                maximumLineCount: 1

                                Behavior on color {
                                    enabled: Config.animDuration > 0
                                    ColorAnimation {
                                        duration: Config.animDuration / 2
                                        easing.type: Easing.OutQuart
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.modified ? NotesUtils.formatTimestamp(modelData.modified) : ""
                                font.family: Config.theme.font
                                font.pixelSize: Config.theme.fontSize - 2
                                color: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.6)
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                visible: !modelData.isCreateButton && text !== ""
                            }
                        }
                    }

                    // Expanded options
                    Column {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.topMargin: 52
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        visible: isExpanded && !isInDeleteMode && !isInRenameMode
                        spacing: 0

                        ListView {
                            id: optionsListView
                            width: parent.width
                            height: 36 * 3
                            interactive: false
                            currentIndex: root.keyboardNavigation ? root.selectedOptionIndex : -1

                            model: [
                                {
                                    text: "Edit",
                                    icon: Icons.edit,
                                    variant: "primary",
                                    textColor: Config.resolveColor(Config.theme.srPrimary.itemColor),
                                    action: function() { openNoteInEditor(modelData.id); }
                                },
                                {
                                    text: "Rename",
                                    icon: Icons.edit,
                                    variant: "secondary",
                                    textColor: Config.resolveColor(Config.theme.srSecondary.itemColor),
                                    action: function() { enterRenameMode(modelData.id); }
                                },
                                {
                                    text: "Delete",
                                    icon: Icons.trash,
                                    variant: "error",
                                    textColor: Config.resolveColor(Config.theme.srError.itemColor),
                                    action: function() { enterDeleteMode(modelData.id); }
                                }
                            ]

                            highlight: StyledRect {
                                width: optionsListView.width
                                height: 36
                                variant: {
                                    let opt = optionsListView.model[optionsListView.currentIndex];
                                    return opt ? opt.variant : "primary";
                                }
                                radius: Styling.radius(-4)
                            }

                            highlightMoveDuration: Config.animDuration > 0 ? Config.animDuration / 2 : 0
                            highlightMoveVelocity: -1
                            highlightResizeDuration: Config.animDuration / 2
                            highlightResizeVelocity: -1

                            delegate: Item {
                                required property var modelData
                                required property int index

                                width: optionsListView.width
                                height: 36

                                Rectangle {
                                    anchors.fill: parent
                                    color: "transparent"

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 8

                                        Text {
                                            text: modelData && modelData.icon ? modelData.icon : ""
                                            font.family: Icons.font
                                            font.pixelSize: 14
                                            font.weight: Font.Bold
                                            textFormat: Text.RichText
                                            color: {
                                                if (optionsListView.currentIndex === index && modelData && modelData.textColor) {
                                                    return modelData.textColor;
                                                }
                                                return Colors.overSurface;
                                            }

                                            Behavior on color {
                                                enabled: Config.animDuration > 0
                                                ColorAnimation {
                                                    duration: Config.animDuration / 2
                                                    easing.type: Easing.OutQuart
                                                }
                                            }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData && modelData.text ? modelData.text : ""
                                            font.family: Config.theme.font
                                            font.pixelSize: Config.theme.fontSize
                                            font.weight: optionsListView.currentIndex === index ? Font.Bold : Font.Normal
                                            color: {
                                                if (optionsListView.currentIndex === index && modelData && modelData.textColor) {
                                                    return modelData.textColor;
                                                }
                                                return Colors.overSurface;
                                            }
                                            elide: Text.ElideRight
                                            maximumLineCount: 1

                                            Behavior on color {
                                                enabled: Config.animDuration > 0
                                                ColorAnimation {
                                                    duration: Config.animDuration / 2
                                                    easing.type: Easing.OutQuart
                                                }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor

                                        onEntered: {
                                            optionsListView.currentIndex = index;
                                            root.selectedOptionIndex = index;
                                            root.keyboardNavigation = false;
                                        }

                                        onClicked: {
                                            if (modelData && modelData.action) {
                                                modelData.action();
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Separator
        Separator {
            Layout.preferredWidth: 2
            Layout.fillHeight: true
            vert: true
        }

        // Right panel: Split view (Editor + Preview)
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8
            visible: currentNoteId !== ""

            property bool syncingScroll: false

            function syncEditorToPreview() {
                if (syncingScroll) return;
                syncingScroll = true;
                let editorMaxY = editorFlickable.contentHeight - editorFlickable.height;
                let previewMaxY = previewFlickable.contentHeight - previewFlickable.height;
                if (editorMaxY > 0 && previewMaxY > 0) {
                    let ratio = editorFlickable.contentY / editorMaxY;
                    previewFlickable.contentY = ratio * previewMaxY;
                }
                syncingScroll = false;
            }

            function syncPreviewToEditor() {
                if (syncingScroll) return;
                syncingScroll = true;
                let editorMaxY = editorFlickable.contentHeight - editorFlickable.height;
                let previewMaxY = previewFlickable.contentHeight - previewFlickable.height;
                if (editorMaxY > 0 && previewMaxY > 0) {
                    let ratio = previewFlickable.contentY / previewMaxY;
                    editorFlickable.contentY = ratio * editorMaxY;
                }
                syncingScroll = false;
            }

            // Left side: Plain text editor
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"

                Flickable {
                    id: editorFlickable
                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: noteEditor.contentHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    onContentYChanged: parent.parent.syncEditorToPreview()

                    TextArea.flickable: TextArea {
                        id: noteEditor
                        text: currentNoteContent
                        textFormat: TextEdit.PlainText
                        font.family: "monospace"
                        font.pixelSize: Config.theme.fontSize
                        color: Colors.overSurface
                        wrapMode: TextEdit.Wrap
                        selectByMouse: true
                        placeholderText: "Start typing..."
                        background: Rectangle {
                            color: "transparent"
                        }

                        onTextChanged: {
                            if (currentNoteId && !loadingNote) {
                                editorDirty = true;
                                saveDebounceTimer.restart();
                            }
                        }

                        onCursorRectangleChanged: {
                            // Ensure flickable follows cursor, then sync
                            Qt.callLater(() => parent.parent.parent.syncEditorToPreview());
                        }

                        Keys.onEscapePressed: {
                            searchInput.focusInput();
                        }

                        Keys.onTabPressed: event => {
                            insert(cursorPosition, "    ");
                            event.accepted = true;
                        }
                    }

                    ScrollBar.vertical: ScrollBar {
                        active: true
                    }
                }
            }

            // Separator
            Separator {
                Layout.preferredWidth: 2
                Layout.fillHeight: true
                vert: true
            }

            // Right side: Markdown preview
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"

                Flickable {
                    id: previewFlickable
                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: markdownPreview.implicitHeight + 32
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    onContentYChanged: parent.parent.syncPreviewToEditor()

                    TextArea {
                        id: markdownPreview
                        width: previewFlickable.width
                        height: implicitHeight
                        text: noteEditor.text
                        textFormat: TextEdit.MarkdownText
                        font.family: Config.theme.font
                        font.pixelSize: Config.theme.fontSize
                        color: Colors.overSurface
                        wrapMode: TextEdit.Wrap
                        readOnly: true
                        selectByMouse: true
                        background: Rectangle {
                            color: "transparent"
                        }
                    }

                    ScrollBar.vertical: ScrollBar {
                        active: true
                    }
                }
            }
        }

        // Placeholder when no note selected
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"
            visible: currentNoteId === ""

            Text {
                anchors.centerIn: parent
                text: "Select or create a note"
                font.family: Config.theme.font
                font.pixelSize: Config.theme.fontSize
                color: Colors.outline
            }
        }

        // Loading overlay
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0.8)
            visible: loadingNote
            radius: Styling.radius(4)

            Text {
                anchors.centerIn: parent
                text: Icons.spinnerGap
                font.family: Icons.font
                font.pixelSize: 24
                color: Colors.overSurface

                RotationAnimator on rotation {
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                    running: loadingNote
                }
            }
        }
    }
}
