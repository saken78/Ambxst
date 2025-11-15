pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property bool active: false
    property var items: []
    property var imageDataById: ({})
    property int revision: 0
    readonly property string watchersScriptPath: Qt.resolvedUrl("../../scripts/cliphist.sh").toString().replace("file://", "")

    // Cola de trabajos para decodificar imágenes
    property var _b64Queue: []
    property bool _b64Processing: false

    signal listCompleted


    // Procesos
    property Process dependencyCheckProcess: Process {
        command: ["which", "cliphist"]
        running: false

        onExited: function (code) {
            root.active = (code === 0);
            if (root.active) {
                ensureWatchersRunning();
                Qt.callLater(root.list);
            }
        }
    }

    property Process ensureWatchersProcess: Process {
        running: false
        command: ["bash", "-lc", watchersScriptPath]

        onExited: function (code) {
            if (code !== 0) {
                console.warn("ClipboardService: failed to start clipboard watchers, exit code:", code);
            }
        }
    }

    property Process listProcess: Process {
        command: ["cliphist", "list"]
        running: false

        stdout: StdioCollector {
            waitForEnd: true

            onStreamFinished: {
                var clipboardItems = [];
                var lines = text.trim().split('\n');

                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line.length === 0)
                        continue;

                    var parts = line.split('\t');
                    if (parts.length < 2)
                        continue;

                    var id = parts[0];
                    var content = parts.slice(1).join('\t');

                    // Filtrar contenido HTML problemático
                    if (content.includes("<meta http-equiv"))
                        continue;

                    var isImage = isImageData(content);
                    var mime = "text/plain";

                    if (isImage) {
                        if (content.includes("png"))
                            mime = "image/png";
                        else if (content.includes("jpg") || content.includes("jpeg"))
                            mime = "image/jpeg";
                        else if (content.includes("gif"))
                            mime = "image/gif";
                        else if (content.includes("webp"))
                            mime = "image/webp";
                        else
                            mime = "image/png"; // default
                    }

                    clipboardItems.push({
                        id: id,
                        preview: isImage ? "[Image]" : (content.length > 100 ? content.substring(0, 97) + "..." : content),
                        fullContent: content,
                        mime: mime,
                        isImage: isImage
                    });
                }

                root.items = clipboardItems;
                root.listCompleted();
            }
        }

        onExited: function (code) {
            if (code !== 0) {
                root.items = [];
                root.listCompleted();
            }
        }
    }

    property Process decodeB64Process: Process {
        property string itemId: ""
        property string itemMime: ""
        running: false

        stdout: StdioCollector {
            waitForEnd: true

            onStreamFinished: {
                if (text.length > 0) {
                    // Limpiar el base64 (remover saltos de línea y espacios)
                    var cleanBase64 = text.replace(/\s/g, '');
                    // Crear data URL desde los datos base64
                    var dataUrl = "data:" + decodeB64Process.itemMime + ";base64," + cleanBase64;

                    // Guardar en cache
                    root.imageDataById[decodeB64Process.itemId] = dataUrl;
                    root.revision++;
                }

                // Procesar siguiente trabajo en la cola
                root._b64Processing = false;
                Qt.callLater(root._startNextB64);
            }
        }

        onExited: function (code) {
            if (code !== 0) {
                console.log("ClipboardService: Failed to decode image", decodeB64Process.itemId);
            }

            // Procesar siguiente trabajo en la cola
            root._b64Processing = false;
            Qt.callLater(root._startNextB64);
        }
    }

    property Process clearProcess: Process {
        command: ["cliphist", "wipe"]
        running: false

        onExited: function (code) {
            if (code === 0) {
                // Limpiar el cache local
                root.items = [];
                root.imageDataById = {};
                root.revision++;
                root.listCompleted();
            } else {
                console.log("ClipboardService: Failed to clear clipboard history");
            }
        }
    }

    property Process deleteProcess: Process {
        property string itemId: ""
        running: false

        onExited: function (code) {
            if (code === 0) {
                Qt.callLater(root.list);
            } else {
                console.log("ClipboardService: Failed to delete item:", deleteProcess.itemId);
            }
        }
    }

    property Process getFullContentProcess: Process {
        property string itemId: ""
        running: false

        stdout: StdioCollector {
            waitForEnd: true

            onStreamFinished: {
                // Emitir señal con el contenido completo
                root.fullContentRetrieved(getFullContentProcess.itemId, text);
            }
        }

        onExited: function (code) {
            if (code !== 0) {
                console.log("ClipboardService: Failed to get full content for:", getFullContentProcess.itemId);
                root.fullContentRetrieved(getFullContentProcess.itemId, "");
            }
        }
    }

    signal fullContentRetrieved(string itemId, string content)

    function ensureWatchersRunning() {
        if (!watchersScriptPath)
            return;
        if (!ensureWatchersProcess.running) {
            ensureWatchersProcess.running = true;
        }
    }

    function checkCliphistAvailability() {
        dependencyCheckProcess.running = true;
    }

    function list() {
        if (!active)
            return;
        listProcess.running = true;
    }

    function clear() {
        if (!active)
            return;
        clearProcess.running = true;
    }

    function deleteItem(id) {
        if (!active)
            return;
        deleteProcess.itemId = id;
        deleteProcess.command = ["bash", "-c", `echo "${id}" | cliphist delete`];
        deleteProcess.running = true;
    }

    function isImageData(content) {
        return content.includes("[[ binary data") && (content.includes("png") || content.includes("jpg") || content.includes("jpeg") || content.includes("gif") || content.includes("bmp") || content.includes("webp"));
    }

    function decodeToDataUrl(id, mime) {
        // Si ya está en cache, no hacer nada
        if (imageDataById[id]) {
            return;
        }

        // Agregar a la cola
        _b64Queue.push({
            id: id,
            mime: mime
        });

        // Iniciar procesamiento si no está en progreso
        if (!_b64Processing) {
            Qt.callLater(_startNextB64);
        }
    }

    function _startNextB64() {
        if (_b64Processing || _b64Queue.length === 0) {
            return;
        }

        var job = _b64Queue.shift();
        _b64Processing = true;

        decodeB64Process.itemId = job.id;
        decodeB64Process.itemMime = job.mime;
        decodeB64Process.command = ["bash", "-c", `cliphist decode "${job.id}" | base64 -w 0`];
        decodeB64Process.running = true;
    }

    function getImageData(id) {
        return imageDataById[id] || "";
    }

    function getFullContent(id) {
        if (!active)
            return;
        getFullContentProcess.itemId = id;
        getFullContentProcess.command = ["bash", "-c", `cliphist decode "${id}"`];
        getFullContentProcess.running = true;
    }

    Component.onCompleted: {
        checkCliphistAvailability();
    }
}
