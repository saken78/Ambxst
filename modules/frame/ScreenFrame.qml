import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

Item {
    id: root

    required property ShellScreen targetScreen

    readonly property alias frameEnabled: frameContent.frameEnabled
    readonly property alias thickness: frameContent.thickness
    readonly property alias actualFrameSize: frameContent.actualFrameSize
    readonly property alias innerRadius: frameContent.innerRadius

    // Expose specific side thicknesses for reservation logic
    readonly property alias topThickness: frameContent.topThickness
    readonly property alias bottomThickness: frameContent.bottomThickness
    readonly property alias leftThickness: frameContent.leftThickness
    readonly property alias rightThickness: frameContent.rightThickness
    
    readonly property bool containBar: Config.bar?.containBar ?? false
    readonly property string barPos: Config.bar?.position ?? "top"

    Item {
        id: noInputRegion
        width: 0
        height: 0
        visible: false
    }

    PanelWindow {
        id: topFrame
        screen: root.targetScreen
        visible: root.frameEnabled
        implicitHeight: root.topThickness
        color: "transparent"
        anchors {
            left: true
            right: true
            top: true
        }
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:screenFrame:top"
        exclusionMode: (root.containBar && root.barPos === "top") ? ExclusionMode.Normal : ExclusionMode.Ignore
        exclusiveZone: root.topThickness
        mask: Region { item: noInputRegion }
    }

    PanelWindow {
        id: bottomFrame
        screen: root.targetScreen
        visible: root.frameEnabled
        implicitHeight: root.bottomThickness
        color: "transparent"
        anchors {
            left: true
            right: true
            bottom: true
        }
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:screenFrame:bottom"
        exclusionMode: (root.containBar && root.barPos === "bottom") ? ExclusionMode.Normal : ExclusionMode.Ignore
        exclusiveZone: root.bottomThickness
        mask: Region { item: noInputRegion }
    }

    PanelWindow {
        id: leftFrame
        screen: root.targetScreen
        visible: root.frameEnabled
        implicitWidth: root.leftThickness
        color: "transparent"
        anchors {
            top: true
            bottom: true
            left: true
        }
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:screenFrame:left"
        exclusionMode: (root.containBar && root.barPos === "left") ? ExclusionMode.Normal : ExclusionMode.Ignore
        exclusiveZone: root.leftThickness
        mask: Region { item: noInputRegion }
    }

    PanelWindow {
        id: rightFrame
        screen: root.targetScreen
        visible: root.frameEnabled
        implicitWidth: root.rightThickness
        color: "transparent"
        anchors {
            top: true
            bottom: true
            right: true
        }
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:screenFrame:right"
        exclusionMode: (root.containBar && root.barPos === "right") ? ExclusionMode.Normal : ExclusionMode.Ignore
        exclusiveZone: root.rightThickness
        mask: Region { item: noInputRegion }
    }

    PanelWindow {
        id: frameOverlay
        screen: root.targetScreen
        visible: root.frameEnabled
        color: "transparent"
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:screenFrame:overlay"
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        mask: Region { item: noInputRegion }

        ScreenFrameContent {
            id: frameContent
            anchors.fill: parent
            targetScreen: root.targetScreen
        }
    }
}
