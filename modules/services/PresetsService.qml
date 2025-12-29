pragma Singleton

import QtQuick
import QtQml
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Available presets
    property var presets: []

    // Current preset being loaded/saved
    property string currentPreset: ""

    // Config directory paths
    readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/Ambxst"
    readonly property string presetsDir: configDir + "/presets"

    // Signal when presets change
    signal presetsUpdated()

    // Scan presets directory
    function scanPresets() {
        scanProcess.running = true
    }

    // Load a preset by name
    function loadPreset(presetName: string) {
        if (presetName === "") {
            console.warn("Cannot load empty preset name")
            return
        }

        console.log("Loading preset:", presetName)
        currentPreset = presetName

        // Find the preset object to get its config files
        const preset = presets.find(p => p.name === presetName)
        if (!preset) {
            console.warn("Preset not found in list:", presetName)
            return
        }

        // Build command to copy config files
        const presetPath = presetsDir + "/" + presetName
        let copyCmd = ""
        
        for (const configFile of preset.configFiles) {
             const jsonFile = configFile.replace('.js', '.json')
             const srcPath = presetPath + "/" + jsonFile
             const dstPath = configDir + "/config/" + jsonFile
             copyCmd += `cp "${srcPath}" "${dstPath}" && `
        }
        
        if (copyCmd.length > 0) {
            copyCmd = copyCmd.slice(0, -4) // Remove last " && "
            loadProcess.command = ["sh", "-c", copyCmd]
            loadProcess.running = true
        } else {
            console.warn("No config files found in preset:", presetName)
        }
    }

    // Save current config as preset
    function savePreset(presetName: string, configFiles: var) {
        if (presetName === "") {
            console.warn("Cannot save preset with empty name")
            return
        }

        if (configFiles.length === 0) {
            console.warn("No config files selected for preset")
            return
        }

        console.log("Saving preset:", presetName, "with files:", configFiles)

        // Create preset directory and copy config files
        const presetPath = presetsDir + "/" + presetName
        const createCmd = `mkdir -p "${presetPath}"`

        let copyCmd = ""
        for (const configFile of configFiles) {
            const jsonFile = configFile.replace('.js', '.json')
            // The source is configDir (~/.config/Ambxst), NOT configDir/config
            // But wait, the configDir property is defined as ~/.config/Ambxst below?
            // Let's check the property definition.
            // property string configDir: ... + "/Ambxst"
            // But Config.qml says configDir is ... + "/Ambxst/config"
            // We need to match Config.qml's path.
            
            // In Config.qml: property string configDir: ... + "/Ambxst/config"
            // Here: readonly property string configDir: ... + "/Ambxst"
            // This is a mismatch!
            
            // We should use the same path as Config.qml for reading/writing config files.
            // Let's assume the files are in .../Ambxst/config based on Config.qml and ls output.
            
            const srcPath = configDir + "/config/" + jsonFile 
            const dstPath = presetPath + "/" + jsonFile
            copyCmd += `cp "${srcPath}" "${dstPath}" && `
        }
        copyCmd = copyCmd.slice(0, -4) // Remove last " && "

        const fullCmd = `${createCmd} && ${copyCmd}`
        saveProcess.command = ["sh", "-c", fullCmd]
        saveProcess.running = true

        root.pendingPresetName = presetName
    }

    // Internal properties for saving
    property string pendingPresetName: ""

    // Scan presets process
    Process {
        id: scanProcess
        // Find all JSON files in subdirectories of presetsDir (depth 2)
        // Structure: presets/PresetName/config.json
        command: ["find", presetsDir, "-mindepth", "2", "-maxdepth", "2", "-name", "*.json"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const files = text.trim().split('\n').filter(line => line.length > 0)
                const presetsMap = {}

                for (const file of files) {
                    // file: /path/to/presets/PresetName/config.json
                    const parts = file.split('/')
                    const configName = parts.pop() // config.json
                    const presetName = parts.pop() // PresetName
                    
                    if (!presetsMap[presetName]) {
                        // Reconstruct path: /path/to/presets + / + PresetName
                        // We can't trust parts.join('/') because parts is now missing the last two elements.
                        // However, we know presetsDir and presetName.
                        presetsMap[presetName] = {
                            name: presetName,
                            path: root.presetsDir + '/' + presetName,
                            configFiles: []
                        }
                    }
                    
                    // Convert .json to .js for UI display
                    presetsMap[presetName].configFiles.push(configName.replace('.json', '.js'))
                }

                // Convert map to array
                const newPresets = Object.values(presetsMap)
                // Sort by name
                newPresets.sort((a, b) => a.name.localeCompare(b.name))

                root.presets = newPresets
                root.presetsUpdated()
            }
        }
        
        onExited: function(exitCode) {
             if (exitCode !== 0) {
                // If find fails, it might be empty or error.
                // We keep existing presets or clear if needed.
                // Usually find returns 0 even if empty.
             }
        }
    }

    // Save process
    Process {
        id: saveProcess
        running: false

        onExited: function(exitCode) {
            if (exitCode === 0) {
                console.log("Preset saved successfully:", root.pendingPresetName)
                Quickshell.execDetached(["notify-send", "Preset Saved", `Preset "${root.pendingPresetName}" saved successfully.`])
                // Trigger scan
                root.scanProcess.running = true
            } else {
                console.warn("Failed to save preset:", root.pendingPresetName)
                Quickshell.execDetached(["notify-send", "Error", `Failed to save preset "${root.pendingPresetName}".`])
            }
            root.pendingPresetName = ""
        }
    }

    // Load process
    Process {
        id: loadProcess
        running: false

        onExited: function(exitCode) {
            if (exitCode === 0) {
                console.log("Preset loaded successfully:", root.currentPreset)
                Quickshell.execDetached(["notify-send", "Preset Loaded", `Preset "${root.currentPreset}" loaded successfully.`])
            } else {
                console.warn("Failed to load preset:", root.currentPreset)
                Quickshell.execDetached(["notify-send", "Error", `Failed to load preset "${root.currentPreset}".`])
            }
            root.currentPreset = ""
        }
    }

    // Directory watcher for the main presets directory (detects new/deleted presets)
    FileView {
        path: presetsDir
        watchChanges: true
        printErrors: false

        onFileChanged: {
            console.log("Presets directory changed, rescanning...")
            scanProcess.running = true
        }
    }

    // Watch individual preset directories for content changes (added/removed files inside a preset)
    Instantiator {
        model: root.presets
        delegate: FileView {
            required property var modelData
            path: modelData.path
            watchChanges: true
            printErrors: false
            onFileChanged: {
                console.log("Preset modified (content change):", modelData.name)
                // Use a debouncer or simple timer to avoid spamming scans if multiple files change
                root.scanProcess.running = true
            }
        }
    }
    
    // Init process (create directory)
    Process {
        id: initProcess
        command: ["mkdir", "-p", presetsDir]
        running: false
        onExited: function(exitCode) {
            if (exitCode === 0) {
                root.scanPresets()
            }
        }
    }

    // Initialize
    Component.onCompleted: {
        console.log("PresetsService created, presetsDir:", presetsDir)
        initProcess.running = true
    }
}
