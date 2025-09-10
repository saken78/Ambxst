import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.theme
import qs.modules.components
import qs.modules.globals
import qs.config

Rectangle {
    id: root
    focus: true

    property string searchText: ""
    property bool showResults: searchText.length > 0
    property int selectedIndex: -1
    property int selectedImageIndex: -1
    property var clipboardItems: []
    property var imageItems: []
    property var textItems: []
    property bool isImageSectionFocused: false
    property string cacheDir: "/tmp/ambyst_clipboard_cache"
    property var pendingImageProcesses: []

    signal itemSelected

    onSelectedIndexChanged: {
        if (selectedIndex === -1 && textResultsList.count > 0) {
            textResultsList.positionViewAtIndex(0, ListView.Beginning);
        }
    }

    onSearchTextChanged: {
        updateFilteredItems();
    }

    function clearSearch() {
        searchText = "";
        selectedIndex = -1;
        selectedImageIndex = -1;
        isImageSectionFocused = false;
        searchInput.focusInput();
        updateFilteredItems();
    }

    function focusSearchInput() {
        searchInput.focusInput();
    }

    function updateFilteredItems() {
        var newImageItems = [];
        var newTextItems = [];

        for (var i = 0; i < clipboardItems.length; i++) {
            var item = clipboardItems[i];
            var content = item.content || "";
            
            if (searchText.length === 0 || content.toLowerCase().includes(searchText.toLowerCase())) {
                if (item.isImage) {
                    newImageItems.push(item);
                } else {
                    newTextItems.push(item);
                }
            }
        }

        imageItems = newImageItems;
        textItems = newTextItems;

        if (searchText.length > 0 && textItems.length > 0 && !isImageSectionFocused) {
            selectedIndex = 0;
            textResultsList.currentIndex = 0;
        } else if (searchText.length === 0) {
            selectedIndex = -1;
            selectedImageIndex = -1;
            textResultsList.currentIndex = -1;
        }
    }

    function isImageData(content) {
        return content.includes("[[ binary data") && 
               (content.includes("png") || content.includes("jpg") || content.includes("jpeg") || 
                content.includes("gif") || content.includes("bmp") || content.includes("webp"));
    }

    function refreshClipboardHistory() {
        cliphist.running = true;
    }

    function copyToClipboard(itemId) {
        copyProcess.command = ["bash", "-c", `cliphist decode "${itemId}" | wl-copy`];
        copyProcess.running = true;
    }

    function generateImageCache(itemId, isFirst = false) {
        var imagePath = cacheDir + "/img_" + itemId + ".png";
        
        // Evitar procesar la misma imagen múltiples veces
        if (pendingImageProcesses.indexOf(itemId) !== -1) {
            return imagePath;
        }
        
        pendingImageProcesses.push(itemId);
        
        // Para el primer elemento, añadir un pequeño delay para evitar problemas de timing
        if (isFirst) {
            Qt.callLater(() => {
                if (!imageDecodeProcess.running) {
                    imageDecodeProcess.command = ["bash", "-c", `mkdir -p "${cacheDir}" && cliphist decode "${itemId}" > "${imagePath}" && echo "Image cached: ${imagePath}"`];
                    imageDecodeProcess.itemId = itemId;
                    imageDecodeProcess.imagePath = imagePath;
                    imageDecodeProcess.running = true;
                }
            });
        } else {
            if (!imageDecodeProcess.running) {
                imageDecodeProcess.command = ["bash", "-c", `mkdir -p "${cacheDir}" && cliphist decode "${itemId}" > "${imagePath}"`];
                imageDecodeProcess.itemId = itemId;
                imageDecodeProcess.imagePath = imagePath;
                imageDecodeProcess.running = true;
            }
        }
        
        return imagePath;
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

    // Proceso para obtener lista del clipboard
    Process {
        id: cliphist
        command: ["cliphist", "list"]
        running: false

        stdout: StdioCollector {
            id: cliphistCollector
            waitForEnd: true

            onStreamFinished: {
                var items = [];
                var lines = text.trim().split('\n');
                
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line.length === 0) continue;
                    
                    var parts = line.split('\t');
                    if (parts.length < 2) continue;
                    
                    var id = parts[0];
                    var content = parts.slice(1).join('\t');
                    
                    // Filtrar contenido HTML problemático
                    if (content.includes("<meta http-equiv")) continue;
                    
                    var isImage = root.isImageData(content);
                    var imagePath = "";
                    
                    if (isImage) {
                        imagePath = root.generateImageCache(id, i === 0);
                    }
                    
                    items.push({
                        id: id,
                        content: content,
                        isImage: isImage,
                        imagePath: imagePath,
                        displayText: isImage ? "[Image]" : (content.length > 100 ? content.substring(0, 97) + "..." : content)
                    });
                }
                
                root.clipboardItems = items;
                root.updateFilteredItems();
            }
        }

        onExited: function (exitCode) {
            if (exitCode !== 0) {
                root.clipboardItems = [];
                root.updateFilteredItems();
            }
        }
    }

    // Proceso para copiar al portapapeles
    Process {
        id: copyProcess
        running: false

        onExited: function (code) {
            if (code === 0) {
                root.itemSelected();
            }
        }
    }

    // Proceso para decodificar imágenes
    Process {
        id: imageDecodeProcess
        property string itemId: ""
        property string imagePath: ""
        running: false

        onExited: function (code) {
            if (code === 0 && imagePath) {
                // Actualizar el item correspondiente con la ruta de imagen
                for (var i = 0; i < root.clipboardItems.length; i++) {
                    if (root.clipboardItems[i].id === itemId) {
                        root.clipboardItems[i].imagePath = imagePath;
                        break;
                    }
                }
                // Forzar actualización de la vista
                Qt.callLater(() => {
                    root.updateFilteredItems();
                });
            }
            
            // Remover del array de procesos pendientes
            var index = pendingImageProcesses.indexOf(itemId);
            if (index !== -1) {
                pendingImageProcesses.splice(index, 1);
            }
        }
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: 12

        // Barra de búsqueda
        SearchInput {
            id: searchInput
            Layout.fillWidth: true
            text: root.searchText
            placeholderText: "Search clipboard history..."
            iconText: ""

            onSearchTextChanged: text => {
                root.searchText = text;
            }

            onAccepted: {
                if (root.isImageSectionFocused && root.selectedImageIndex >= 0 && root.selectedImageIndex < root.imageItems.length) {
                    var selectedImage = root.imageItems[root.selectedImageIndex];
                    root.copyToClipboard(selectedImage.id);
                } else if (!root.isImageSectionFocused && root.selectedIndex >= 0 && root.selectedIndex < root.textItems.length) {
                    var selectedText = root.textItems[root.selectedIndex];
                    root.copyToClipboard(selectedText.id);
                }
            }

            onEscapePressed: {
                root.itemSelected();
            }

            onDownPressed: {
                if (root.isImageSectionFocused) {
                    // Cambiar de sección de imágenes a textos
                    root.isImageSectionFocused = false;
                    if (root.textItems.length > 0) {
                        root.selectedIndex = 0;
                        textResultsList.currentIndex = 0;
                    }
                } else if (textResultsList.count > 0) {
                    if (root.selectedIndex === -1) {
                        root.selectedIndex = 0;
                        textResultsList.currentIndex = 0;
                    } else if (root.selectedIndex < textResultsList.count - 1) {
                        root.selectedIndex++;
                        textResultsList.currentIndex = root.selectedIndex;
                    }
                }
            }

            onUpPressed: {
                if (root.isImageSectionFocused) {
                    // Mantenerse en sección de imágenes
                } else if (root.selectedIndex > 0) {
                    root.selectedIndex--;
                    textResultsList.currentIndex = root.selectedIndex;
                } else if (root.selectedIndex === 0 && root.imageItems.length > 0) {
                    // Cambiar de textos a imágenes
                    root.isImageSectionFocused = true;
                    root.selectedIndex = -1;
                    textResultsList.currentIndex = -1;
                    if (root.selectedImageIndex === -1) {
                        root.selectedImageIndex = 0;
                    }
                }
            }

            onLeftPressed: {
                if (root.isImageSectionFocused && root.selectedImageIndex > 0) {
                    root.selectedImageIndex--;
                }
            }

            onRightPressed: {
                if (root.isImageSectionFocused && root.selectedImageIndex < root.imageItems.length - 1) {
                    root.selectedImageIndex++;
                }
            }
        }

        // Sección de imágenes horizontal
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            visible: root.imageItems.length > 0

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: root.isImageSectionFocused ? Colors.adapter.primary : Colors.adapter.outline
                border.width: 1
                radius: Config.roundness > 0 ? Config.roundness : 0

                Behavior on border.color {
                    ColorAnimation {
                        duration: Config.animDuration / 2
                        easing.type: Easing.OutQuart
                    }
                }

                ScrollView {
                    id: imageScrollView
                    anchors.fill: parent
                    anchors.margins: 4
                    ScrollBar.vertical.policy: ScrollBar.AlwaysOff
                    ScrollBar.horizontal.policy: ScrollBar.AsNeeded
                    clip: true

                    Row {
                        spacing: 8
                        height: parent.height

                        Repeater {
                            model: root.imageItems

                            Rectangle {
                                property int itemIndex: index
                                width: 64
                                height: 64
                                color: root.isImageSectionFocused && root.selectedImageIndex === index ? 
                                       Colors.adapter.primary : Colors.adapter.surface
                                radius: Config.roundness > 0 ? Config.roundness - 2 : 0

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Config.animDuration / 2
                                        easing.type: Easing.OutQuart
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true

                                    onEntered: {
                                        if (!root.isImageSectionFocused) {
                                            root.isImageSectionFocused = true;
                                            root.selectedIndex = -1;
                                            textResultsList.currentIndex = -1;
                                        }
                                        root.selectedImageIndex = index;
                                    }

                                    onClicked: {
                                        root.copyToClipboard(modelData.id);
                                    }
                                }

                                // Preview de imagen real o placeholder
                                Item {
                                    anchors.centerIn: parent
                                    width: 48
                                    height: 48

                                    // Imagen real si está disponible
                                    Image {
                                        id: imagePreview
                                        anchors.fill: parent
                                        fillMode: Image.PreserveAspectCrop
                                        visible: status === Image.Ready
                                        source: modelData.imagePath ? "file://" + modelData.imagePath : ""
                                        clip: true
                                        
                                        onStatusChanged: {
                                            if (status === Image.Error) {
                                                console.log("Error loading image:", source);
                                            }
                                        }
                                    }

                                    // Placeholder cuando la imagen no está disponible
                                    Rectangle {
                                        anchors.fill: parent
                                        color: Colors.adapter.primary
                                        radius: Config.roundness > 0 ? Config.roundness - 4 : 0
                                        visible: imagePreview.status !== Image.Ready

                                        Text {
                                            anchors.centerIn: parent
                                            text: Icons.image
                                            font.family: Icons.font
                                            font.pixelSize: 24
                                            color: Colors.adapter.overPrimary
                                        }
                                    }

                                    // Indicador de carga
                                    Rectangle {
                                        anchors.fill: parent
                                        color: Colors.adapter.surface
                                        radius: Config.roundness > 0 ? Config.roundness - 4 : 0
                                        visible: imagePreview.status === Image.Loading
                                        opacity: 0.8

                                        Text {
                                            anchors.centerIn: parent
                                            text: "..."
                                            font.family: Config.theme.font
                                            font.pixelSize: 16
                                            color: Colors.adapter.overSurface
                                        }
                                    }
                                }

                                // Highlight cuando está seleccionado
                                Rectangle {
                                    anchors.fill: parent
                                    color: "transparent"
                                    border.color: Colors.adapter.primary
                                    border.width: root.isImageSectionFocused && root.selectedImageIndex === index ? 2 : 0
                                    radius: parent.radius

                                    Behavior on border.width {
                                        NumberAnimation {
                                            duration: Config.animDuration / 2
                                            easing.type: Easing.OutQuart
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Lista de textos vertical
        ListView {
            id: textResultsList
            Layout.fillWidth: true
            Layout.preferredHeight: 5 * 48
            visible: true
            clip: true

            model: root.textItems
            currentIndex: root.selectedIndex

            onCurrentIndexChanged: {
                if (currentIndex !== root.selectedIndex && !root.isImageSectionFocused) {
                    root.selectedIndex = currentIndex;
                }
            }

            delegate: Rectangle {
                required property var modelData
                required property int index

                width: textResultsList.width
                height: 48
                color: "transparent"
                radius: 16

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true

                    onEntered: {
                        if (root.isImageSectionFocused) {
                            root.isImageSectionFocused = false;
                            root.selectedImageIndex = -1;
                        }
                        root.selectedIndex = index;
                        textResultsList.currentIndex = index;
                    }
                    onClicked: {
                        root.copyToClipboard(modelData.id);
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        color: root.selectedIndex === index && !root.isImageSectionFocused ? 
                               Colors.adapter.overPrimary : Colors.adapter.primary
                        radius: Config.roundness > 0 ? Config.roundness - 4 : 0

                        Behavior on color {
                            ColorAnimation {
                                duration: Config.animDuration / 2
                                easing.type: Easing.OutQuart
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: Icons.clip
                            color: root.selectedIndex === index && !root.isImageSectionFocused ? 
                                   Colors.adapter.primary : Colors.adapter.overPrimary
                            font.family: Icons.font
                            font.pixelSize: 16

                            Behavior on color {
                                ColorAnimation {
                                    duration: Config.animDuration / 2
                                    easing.type: Easing.OutQuart
                                }
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData.displayText
                        color: root.selectedIndex === index && !root.isImageSectionFocused ? 
                               Colors.adapter.overPrimary : Colors.adapter.overBackground
                        font.family: Config.theme.font
                        font.pixelSize: Config.theme.fontSize
                        font.weight: Font.Bold
                        elide: Text.ElideRight

                        Behavior on color {
                            ColorAnimation {
                                duration: Config.animDuration / 2
                                easing.type: Easing.OutQuart
                            }
                        }
                    }
                }
            }

            highlight: Rectangle {
                color: Colors.adapter.primary
                radius: Config.roundness > 0 ? Config.roundness + 4 : 0
                visible: root.selectedIndex >= 0 && !root.isImageSectionFocused
            }

            highlightMoveDuration: Config.animDuration / 2
            highlightMoveVelocity: -1
        }

        // Mensaje cuando no hay elementos
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 200
            visible: root.clipboardItems.length === 0

            Column {
                anchors.centerIn: parent
                spacing: 16

                Text {
                    text: Icons.clipboard
                    font.family: Icons.font
                    font.pixelSize: 48
                    color: Colors.adapter.overBackground
                    opacity: 0.6
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "No clipboard history"
                    font.family: Config.theme.font
                    font.pixelSize: Config.theme.fontSize + 2
                    font.weight: Font.Bold
                    color: Colors.adapter.overBackground
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "Copy something to get started"
                    font.family: Config.theme.font
                    font.pixelSize: Config.theme.fontSize
                    color: Colors.adapter.overBackground
                    opacity: 0.7
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    Component.onCompleted: {
        refreshClipboardHistory();
        Qt.callLater(() => {
            focusSearchInput();
        });
    }
}