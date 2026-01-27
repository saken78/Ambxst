import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.modules.globals
import qs.config

PanelWindow {
    id: panel

    property alias barPosition: barContent.barPosition
    property alias orientation: barContent.orientation
    property alias pinned: barContent.pinned
    property alias hoverActive: barContent.hoverActive
    readonly property alias isMouseOverBar: barContent.isMouseOverBar
    readonly property alias reveal: barContent.reveal

    anchors {
        top: barPosition !== "bottom"
        bottom: barPosition !== "top"
        left: barPosition !== "right"
        right: barPosition !== "left"
    }

    color: "transparent"

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.layer: WlrLayer.Overlay

    // Reserve space only when revealed and pinned (not in auto-hide mode or fullscreen)
    // If containBar is active, the frame handles reservation, so we reserve 0 to avoid double gap
    exclusiveZone: (Config.bar.containBar) ? 0 : ((reveal && pinned && !barContent.activeWindowFullscreen) ? (Config.showBackground ? 44 : 40) : 0)
    exclusionMode: ExclusionMode.Ignore

    // Altura implicita incluye espacio extra para animaciones / futuros elementos.
    implicitHeight: orientation === "horizontal" ? 200 : Screen.height

    mask: Region {
        item: barContent.barHitbox
    }

    Component.onCompleted: {
        Visibilities.registerBar(screen.name, barContent);
        Visibilities.registerBarPanel(screen.name, panel);
    }

    Component.onDestruction: {
        Visibilities.unregisterBar(screen.name);
        Visibilities.unregisterBarPanel(screen.name);
    }

    BarContent {
        id: barContent
        anchors.fill: parent
        screen: panel.screen
    }
}
