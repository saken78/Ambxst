import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray
import qs.modules.components
import qs.modules.theme
import qs.config

BarPopup {
    id: root

    required property SystemTrayItem item
    property var menuHandle: item.menu

    // Use a reasonable width for the menu
    contentWidth: 220
    // Height adapts to content, with a max limit if needed
    contentHeight: Math.min(itemsColumn.implicitHeight, 400)
    
    // Configura BarPopup para asegurar offset correcto si Frame está activo
    popupPadding: 8
    visualMargin: 8

    // Using QsMenuOpener to access menu items
    QsMenuOpener {
        id: menuOpener
        menu: root.menuHandle
    }

    ScrollView {
        anchors.fill: parent
        // Remove margins here if BarPopup already has padding
        // BarPopup has contentContainer with margins: root.popupPadding (default 8)
        // So we don't need extra margins here unless we want more.
        
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            id: itemsColumn
            width: parent.width
            spacing: 2

            Repeater {
                model: menuOpener.children ? menuOpener.children.values : []
                
                delegate: SystrayMenuItem {
                    required property var modelData
                    
                    Layout.fillWidth: true
                    
                    textStr: modelData.text || ""
                    iconSource: modelData.icon || ""
                    isImageIcon: iconSource.indexOf("/") !== -1 || iconSource.indexOf(".") !== -1
                    isSeparator: modelData.isSeparator || false
                    
                    onClicked: {
                        if (modelData.triggered) {
                            modelData.triggered();
                        }
                        root.close();
                    }
                }
            }
        }
    }
}
