import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs.modules.theme
import qs.modules.services
import qs.modules.globals
import qs.modules.components
import qs.config

Item {
    id: root
    
    implicitWidth: 290
    implicitHeight: hovered ? expandedHeight : 40
    
    property var currentNotification: Notifications.popupList.length > 0 ? Notifications.popupList[0] : null
    property bool hovered: mouseArea.containsMouse || dashboardAccessMouse.containsMouse || anyButtonHovered
    property bool anyButtonHovered: false
    property bool showingSummary: true
    property int expandedHeight: 120
    property int dashboardAccessHeight: 20
    
    // MouseArea para detectar hover en toda el área
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        z: -1  // Detrás de elementos interactivos
        
        onContainsMouseChanged: {
            if (containsMouse) {
                showingSummary = true
            }
        }
    }
    
    Behavior on implicitHeight {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutBack
            easing.overshoot: 1.1
        }
    }
    
    // Timer para alternar entre summary y body
    Timer {
        id: summaryTimer
        interval: 2000
        running: currentNotification && !hovered && showingSummary
        onTriggered: {
            showingSummary = false
            bodyTimer.start()
        }
    }
    
    Timer {
        id: bodyTimer
        interval: 3000
        running: currentNotification && !hovered && !showingSummary
        onTriggered: {
            showingSummary = true
            summaryTimer.start()
        }
    }
    
    // Manejo del hover - pausa timers de alternancia Y timeout de notificación
    onHoveredChanged: {
        if (hovered) {
            // Pausar timers de alternancia cuando se hace hover
            summaryTimer.stop()
            bodyTimer.stop()
            showingSummary = true // Resetear a summary
            
            // Pausar timer de timeout de la notificación
            if (currentNotification) {
                Notifications.pauseGroupTimers(currentNotification.appName)
            }
        } else {
            // Reiniciar ciclo de alternancia cuando se quita el hover
            if (currentNotification) {
                showingSummary = true
                summaryTimer.restart()
                
                // Reanudar timer de timeout de la notificación
                Notifications.resumeGroupTimers(currentNotification.appName)
            }
        }
    }
    
    Component.onCompleted: {
        if (currentNotification) {
            showingSummary = true
            summaryTimer.start()
        }
    }
    
    onCurrentNotificationChanged: {
        if (currentNotification) {
            showingSummary = true
            summaryTimer.restart()
            bodyTimer.stop()
        } else {
            summaryTimer.stop()
            bodyTimer.stop()
        }
    }
    
    // Vista normal (compacta)
    Item {
        id: compactView
        anchors.fill: parent
        visible: !hovered
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 12
            
            // Icono de aplicación (izquierda)
            Image {
                id: appIcon
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                visible: currentNotification && currentNotification.appIcon !== ""
                source: currentNotification ? currentNotification.appIcon : ""
                fillMode: Image.PreserveAspectFit
            }
            
            // StackView para alternar entre summary y body
            StackView {
                id: contentStack
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: 16
                
                clip: true
                
                // Transiciones verticales personalizadas
                replaceEnter: Transition {
                    PropertyAnimation {
                        property: "y"
                        from: contentStack.height
                        to: 0
                        duration: Config.animDuration
                        easing.type: Easing.OutCubic
                    }
                    PropertyAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: Config.animDuration
                    }
                }
                
                replaceExit: Transition {
                    PropertyAnimation {
                        property: "y"
                        from: 0
                        to: -contentStack.height
                        duration: Config.animDuration
                        easing.type: Easing.OutCubic
                    }
                    PropertyAnimation {
                        property: "opacity"
                        from: 1
                        to: 0
                        duration: Config.animDuration
                    }
                }
                
                // Desactivar transiciones horizontales por defecto
                pushEnter: null
                pushExit: null
                popEnter: null
                popExit: null
                
                Component {
                    id: summaryComponent
                    Text {
                        font.family: Config.theme.font
                        font.pixelSize: Config.theme.fontSize
                        color: Colors.adapter.overBackground
                        elide: Text.ElideRight
                        text: currentNotification ? currentNotification.summary : ""
                    }
                }
                
                Component {
                    id: bodyComponent
                    Text {
                        font.family: Config.theme.font
                        font.pixelSize: Config.theme.fontSize
                        color: Colors.adapter.overBackground
                        elide: Text.ElideRight
                        text: currentNotification ? processNotificationBody(currentNotification.body, currentNotification.appName) : ""
                    }
                }
                
                // Inicializar con summary
                Component.onCompleted: {
                    if (currentNotification) {
                        push(summaryComponent)
                    }
                }
                
                // Manejar cambios de contenido
                Connections {
                    target: root
                    function onShowingSummaryChanged() {
                        if (!currentNotification) return
                        
                        if (showingSummary) {
                            contentStack.replace(summaryComponent)
                        } else {
                            contentStack.replace(bodyComponent)
                        }
                    }
                }
                
                // Actualizar cuando cambie la notificación
                Connections {
                    target: root
                    function onCurrentNotificationChanged() {
                        if (currentNotification) {
                            contentStack.replace(summaryComponent)
                        }
                    }
                }
            }
        }
    }
    
    // Vista expandida (hover)
    Item {
        id: expandedView
        anchors.fill: parent
        visible: hovered
        
        Column {
            anchors.fill: parent
            
            // Rectángulo de acceso al dashboard
            Rectangle {
                id: dashboardAccess
                width: parent.width
                height: dashboardAccessHeight
                color: dashboardAccessMouse.containsMouse ? Colors.adapter.primary : "transparent"
                radius: 8
                
                Behavior on color {
                    ColorAnimation { duration: Config.animDuration / 2 }
                }
                
                MouseArea {
                    id: dashboardAccessMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    propagateComposedEvents: true
                    
                    onClicked: {
                        GlobalStates.dashboardCurrentTab = 0
                        Visibilities.setActiveModule("dashboard")
                    }
                }
                
                Text {
                    anchors.centerIn: parent
                    text: "···"
                    font.family: Config.theme.font
                    font.pixelSize: 10
                    color: dashboardAccessMouse.containsMouse ? Colors.adapter.overPrimary : Colors.adapter.outline
                    
                    Behavior on color {
                        ColorAnimation { duration: Config.animDuration / 2 }
                    }
                }
            }
            
            // Contenido de la notificación expandida
            Item {
                width: parent.width
                height: parent.height - dashboardAccessHeight
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8
                    
                    // Header con app icon y textos
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        
                        // App icon (izquierda)
                        Image {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            visible: currentNotification && currentNotification.appIcon !== ""
                            source: currentNotification ? currentNotification.appIcon : ""
                            fillMode: Image.PreserveAspectFit
                        }
                        
                        // Textos (centro)
                        Column {
                            Layout.fillWidth: true
                            spacing: 2
                            
                            Text {
                                width: parent.width
                                text: currentNotification ? currentNotification.summary : ""
                                font.family: Config.theme.font
                                font.pixelSize: Config.theme.fontSize
                                font.weight: Font.Bold
                                color: Colors.adapter.primary
                                elide: Text.ElideRight
                            }
                            
                            Text {
                                width: parent.width
                                text: currentNotification ? processNotificationBody(currentNotification.body, currentNotification.appName) : ""
                                font.family: Config.theme.font
                                font.pixelSize: Config.theme.fontSize - 1
                                color: Colors.adapter.overBackground
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }
                        }
                    }
                    
                    // Botones de acción
                    RowLayout {
                        Layout.fillWidth: true
                        visible: currentNotification && currentNotification.actions.length > 0
                        spacing: 6
                        
                        Repeater {
                            model: currentNotification ? currentNotification.actions : []
                            
                            Button {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 28
                                
                                text: modelData.text
                                font.family: Config.theme.font
                                font.pixelSize: Config.theme.fontSize - 2
                                hoverEnabled: true
                                
                                onHoveredChanged: {
                                    root.anyButtonHovered = hovered
                                }
                                
                                background: Rectangle {
                                    color: parent.pressed ? Colors.adapter.primary : (parent.hovered ? Colors.surfaceBright : Colors.surfaceContainerHigh)
                                    radius: Config.roundness
                                    
                                    Behavior on color {
                                        ColorAnimation { duration: Config.animDuration / 2 }
                                    }
                                }
                                
                                contentItem: Text {
                                    text: parent.text
                                    font: parent.font
                                    color: parent.pressed ? Colors.adapter.overPrimary : (parent.hovered ? Colors.adapter.overBackground : Colors.adapter.primary)
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    
                                    Behavior on color {
                                        ColorAnimation { duration: Config.animDuration / 2 }
                                    }
                                }
                                
                                onClicked: {
                                    Notifications.attemptInvokeAction(currentNotification.id, modelData.identifier)
                                }
                            }
                        }
                    }
                    
                    // Botones de control (Cerrar/Copiar)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        
                        Button {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 24
                            text: "✕"
                            hoverEnabled: true
                            
                            onHoveredChanged: {
                                root.anyButtonHovered = hovered
                            }
                            
                            background: Rectangle {
                                color: parent.pressed ? Colors.adapter.error : (parent.hovered ? Colors.surfaceBright : Colors.surfaceContainerHigh)
                                radius: Config.roundness
                                
                                Behavior on color {
                                    ColorAnimation { duration: Config.animDuration / 2 }
                                }
                            }
                            
                            contentItem: Text {
                                text: parent.text
                                font.family: Config.theme.font
                                font.pixelSize: 12
                                color: parent.pressed ? Colors.adapter.overError : (parent.hovered ? Colors.adapter.overBackground : Colors.adapter.error)
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                
                                Behavior on color {
                                    ColorAnimation { duration: Config.animDuration / 2 }
                                }
                            }
                            
                            onClicked: {
                                if (currentNotification) {
                                    Notifications.discardNotification(currentNotification.id)
                                }
                            }
                        }
                        
                        Button {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 24
                            text: "📋"
                            hoverEnabled: true
                            
                            onHoveredChanged: {
                                root.anyButtonHovered = hovered
                            }
                            
                            background: Rectangle {
                                color: parent.pressed ? Colors.adapter.primary : (parent.hovered ? Colors.surfaceBright : Colors.surfaceContainerHigh)
                                radius: Config.roundness
                                
                                Behavior on color {
                                    ColorAnimation { duration: Config.animDuration / 2 }
                                }
                            }
                            
                            contentItem: Text {
                                text: parent.text
                                font.family: Config.theme.font
                                font.pixelSize: 12
                                color: parent.pressed ? Colors.adapter.overPrimary : (parent.hovered ? Colors.adapter.overBackground : Colors.adapter.primary)
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                
                                Behavior on color {
                                    ColorAnimation { duration: Config.animDuration / 2 }
                                }
                            }
                            
                            onClicked: {
                                if (currentNotification) {
                                    console.log("Copy:", currentNotification.body)
                                    // TODO: Implementar copia al portapapeles
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Función auxiliar para procesar el cuerpo de la notificación
    function processNotificationBody(body, appName) {
        if (!body) return ""
        
        let processedBody = body
        
        // Limpiar notificaciones de navegadores basados en Chromium
        if (appName) {
            const lowerApp = appName.toLowerCase()
            const chromiumBrowsers = ["brave", "chrome", "chromium", "vivaldi", "opera", "microsoft edge"]
            
            if (chromiumBrowsers.some(name => lowerApp.includes(name))) {
                const lines = body.split('\n\n')
                
                if (lines.length > 1 && lines[0].startsWith('<a')) {
                    processedBody = lines.slice(1).join('\n\n')
                }
            }
        }
        
        return processedBody.replace(/\n/g, " ")
    }
}