import QtQuick
import QtQuick.Controls
import qs.modules.theme

Item {
    property alias text: textItem.text
    property alias color: textItem.color
    property alias font: textItem.font
    property alias horizontalAlignment: textItem.horizontalAlignment
    property alias verticalAlignment: textItem.verticalAlignment
    property alias elide: textItem.elide
    
    implicitWidth: textItem.implicitWidth
    implicitHeight: textItem.implicitHeight
    
    Text {
        id: textItem
        anchors.fill: parent
        font.family: Styling.defaultFont
    }
}