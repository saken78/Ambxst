import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.modules.components
import qs.modules.corners
import qs.modules.services
import qs.modules.theme
import qs.config

Item {
    id: root

    required property ShellScreen targetScreen

    readonly property bool frameEnabled: Config.bar?.frameEnabled ?? false
    readonly property int thickness: {
        // Always return valid number for corners, even if frame is disabled
        const value = Config.bar?.frameThickness;
        if (typeof value !== "number")
            return 6;
        return Math.max(1, Math.min(Math.round(value), 40));
    }
    
    readonly property bool containBar: Config.bar?.containBar ?? false
    readonly property string barPos: Config.bar?.position ?? "top"
    // Assuming standard bar height of 44 plus standard thickness
    // Expansion needs to account for the bar height PLUS the inner thickness to enclose it
    readonly property int barExpansion: 44 + thickness
    
    readonly property int topThickness: thickness + ((containBar && barPos === "top") ? barExpansion : 0)
    readonly property int bottomThickness: thickness + ((containBar && barPos === "bottom") ? barExpansion : 0)
    readonly property int leftThickness: thickness + ((containBar && barPos === "left") ? barExpansion : 0)
    readonly property int rightThickness: thickness + ((containBar && barPos === "right") ? barExpansion : 0)

    readonly property int actualFrameSize: frameEnabled ? thickness : 0
    readonly property int innerRadius: Styling.radius(4)

    // Visual part
    StyledRect {
        id: frameFill
        anchors.fill: parent
        variant: "bg"
        radius: 0
        enableBorder: false
        visible: root.frameEnabled
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: frameMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }
    }

    Item {
        id: frameMask
        anchors.fill: parent
        visible: false
        layer.enabled: true

        Canvas {
            id: frameCanvas
            anchors.fill: parent
            antialiasing: true

            onPaint: {
                const ctx = getContext("2d");
                const w = width;
                const h = height;
                const t = root.thickness;
                // Use innerRadius for the cutout
                const r = Math.min(root.innerRadius, Math.min(w, h) / 2);

                ctx.clearRect(0, 0, w, h);
                if (w <= 0 || h <= 0 || t <= 0)
                    return;

                // Draw outer rectangle (opaque)
                ctx.fillStyle = "white";
                ctx.fillRect(0, 0, w, h);

                // Cut out the inner rectangle
                const innerX = root.leftThickness;
                const innerY = root.topThickness;
                const innerW = w - (root.leftThickness + root.rightThickness);
                const innerH = h - (root.topThickness + root.bottomThickness);
                if (innerW <= 0 || innerH <= 0)
                    return;

                ctx.globalCompositeOperation = "destination-out";
                
                // Draw rounded rect path for cutout
                const rr = Math.min(r, innerW / 2, innerH / 2);
                ctx.beginPath();
                ctx.moveTo(innerX + rr, innerY);
                ctx.arcTo(innerX + innerW, innerY, innerX + innerW, innerY + innerH, rr);
                ctx.arcTo(innerX + innerW, innerY + innerH, innerX, innerY + innerH, rr);
                ctx.arcTo(innerX, innerY + innerH, innerX, innerY, rr);
                ctx.arcTo(innerX, innerY, innerX + innerW, innerY, rr);
                ctx.closePath();
                ctx.fill();

                ctx.globalCompositeOperation = "source-over";
            }
        }
    }

    Connections {
        target: root
        function onThicknessChanged() { frameCanvas.requestPaint(); }
        function onInnerRadiusChanged() { frameCanvas.requestPaint(); }
        function onTopThicknessChanged() { frameCanvas.requestPaint(); }
        function onBottomThicknessChanged() { frameCanvas.requestPaint(); }
        function onLeftThicknessChanged() { frameCanvas.requestPaint(); }
        function onRightThicknessChanged() { frameCanvas.requestPaint(); }
    }

    onWidthChanged: frameCanvas.requestPaint()
    onHeightChanged: frameCanvas.requestPaint()
}
