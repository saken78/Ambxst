// Ejemplo de uso del módulo de workspaces avanzado
import QtQuick
import qs.modules.theme

Rectangle {
    width: 800
    height: 60
    color: "#1e1e1e"
    
    Workspaces {
        id: workspaces
        
        // La propiedad bar ya tiene un valor por defecto en el componente
        
        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
            leftMargin: 20
        }
    }
    
    Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 20
        text: "Workspaces avanzados implementados"
        color: "#ffffff"
        font.family: Styling.defaultFont
    }
}