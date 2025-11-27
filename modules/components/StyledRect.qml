pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell.Widgets
import qs.modules.theme
import qs.config

ClippingRectangle {
    id: root

    clip: true
    antialiasing: true

    required property string variant

    property string gradientOrientation: "vertical"
    property bool enableShadow: false

    readonly property var gradientStops: {
        switch (variant) {
        case "bg":
            return Config.theme.gradBg;
        case "pane":
            return Config.theme.gradPane;
        case "common":
            return Config.theme.gradCommon;
        case "focus":
            return Config.theme.gradFocus;
        case "primary":
            return Config.theme.gradPrimary;
        case "primaryfocus":
            return Config.theme.gradPrimaryFocus;
        case "overprimary":
            return Config.theme.gradOverPrimary;
        case "secondary":
            return Config.theme.gradSecondary;
        case "secondaryfocus":
            return Config.theme.gradSecondaryFocus;
        case "oversecondary":
            return Config.theme.gradOverSecondary;
        case "tertiary":
            return Config.theme.gradTertiary;
        case "tertiaryfocus":
            return Config.theme.gradTertiaryFocus;
        case "overtertiary":
            return Config.theme.gradOverTertiary;
        case "error":
            return Config.theme.gradError;
        case "errorfocus":
            return Config.theme.gradErrorFocus;
        case "overerror":
            return Config.theme.gradOverError;
        default:
            return Config.theme.gradCommon;
        }
    }

    readonly property string gradientType: {
        switch (variant) {
        case "bg":
            return Config.theme.gradBgType;
        case "pane":
            return Config.theme.gradPaneType;
        case "common":
            return Config.theme.gradCommonType;
        case "focus":
            return Config.theme.gradFocusType;
        case "primary":
            return Config.theme.gradPrimaryType;
        case "primaryfocus":
            return Config.theme.gradPrimaryFocusType;
        case "overprimary":
            return Config.theme.gradOverPrimaryType;
        case "secondary":
            return Config.theme.gradSecondaryType;
        case "secondaryfocus":
            return Config.theme.gradSecondaryFocusType;
        case "oversecondary":
            return Config.theme.gradOverSecondaryType;
        case "tertiary":
            return Config.theme.gradTertiaryType;
        case "tertiaryfocus":
            return Config.theme.gradTertiaryFocusType;
        case "overtertiary":
            return Config.theme.gradOverTertiaryType;
        case "error":
            return Config.theme.gradErrorType;
        case "errorfocus":
            return Config.theme.gradErrorFocusType;
        case "overerror":
            return Config.theme.gradOverErrorType;
        default:
            return Config.theme.gradCommonType;
        }
    }

    readonly property real gradientAngle: {
        switch (variant) {
        case "bg":
            return Config.theme.gradBgAngle;
        case "pane":
            return Config.theme.gradPaneAngle;
        case "common":
            return Config.theme.gradCommonAngle;
        case "focus":
            return Config.theme.gradFocusAngle;
        case "primary":
            return Config.theme.gradPrimaryAngle;
        case "primaryfocus":
            return Config.theme.gradPrimaryFocusAngle;
        case "overprimary":
            return Config.theme.gradOverPrimaryAngle;
        case "secondary":
            return Config.theme.gradSecondaryAngle;
        case "secondaryfocus":
            return Config.theme.gradSecondaryFocusAngle;
        case "oversecondary":
            return Config.theme.gradOverSecondaryAngle;
        case "tertiary":
            return Config.theme.gradTertiaryAngle;
        case "tertiaryfocus":
            return Config.theme.gradTertiaryFocusAngle;
        case "overtertiary":
            return Config.theme.gradOverTertiaryAngle;
        case "error":
            return Config.theme.gradErrorAngle;
        case "errorfocus":
            return Config.theme.gradErrorFocusAngle;
        case "overerror":
            return Config.theme.gradOverErrorAngle;
        default:
            return Config.theme.gradCommonAngle;
        }
    }

    readonly property real gradientCenterX: {
        switch (variant) {
        case "bg":
            return Config.theme.gradBgCenterX;
        case "pane":
            return Config.theme.gradPaneCenterX;
        case "common":
            return Config.theme.gradCommonCenterX;
        case "focus":
            return Config.theme.gradFocusCenterX;
        case "primary":
            return Config.theme.gradPrimaryCenterX;
        case "primaryfocus":
            return Config.theme.gradPrimaryFocusCenterX;
        case "overprimary":
            return Config.theme.gradOverPrimaryCenterX;
        case "secondary":
            return Config.theme.gradSecondaryCenterX;
        case "secondaryfocus":
            return Config.theme.gradSecondaryFocusCenterX;
        case "oversecondary":
            return Config.theme.gradOverSecondaryCenterX;
        case "tertiary":
            return Config.theme.gradTertiaryCenterX;
        case "tertiaryfocus":
            return Config.theme.gradTertiaryFocusCenterX;
        case "overtertiary":
            return Config.theme.gradOverTertiaryCenterX;
        case "error":
            return Config.theme.gradErrorCenterX;
        case "errorfocus":
            return Config.theme.gradErrorFocusCenterX;
        case "overerror":
            return Config.theme.gradOverErrorCenterX;
        default:
            return Config.theme.gradCommonCenterX;
        }
    }

    readonly property real gradientCenterY: {
        switch (variant) {
        case "bg":
            return Config.theme.gradBgCenterY;
        case "pane":
            return Config.theme.gradPaneCenterY;
        case "common":
            return Config.theme.gradCommonCenterY;
        case "focus":
            return Config.theme.gradFocusCenterY;
        case "primary":
            return Config.theme.gradPrimaryCenterY;
        case "primaryfocus":
            return Config.theme.gradPrimaryFocusCenterY;
        case "overprimary":
            return Config.theme.gradOverPrimaryCenterY;
        case "secondary":
            return Config.theme.gradSecondaryCenterY;
        case "secondaryfocus":
            return Config.theme.gradSecondaryFocusCenterY;
        case "oversecondary":
            return Config.theme.gradOverSecondaryCenterY;
        case "tertiary":
            return Config.theme.gradTertiaryCenterY;
        case "tertiaryfocus":
            return Config.theme.gradTertiaryFocusCenterY;
        case "overtertiary":
            return Config.theme.gradOverTertiaryCenterY;
        case "error":
            return Config.theme.gradErrorCenterY;
        case "errorfocus":
            return Config.theme.gradErrorFocusCenterY;
        case "overerror":
            return Config.theme.gradOverErrorCenterY;
        default:
            return Config.theme.gradCommonCenterY;
        }
    }

    readonly property var borderData: {
        switch (variant) {
        case "bg":
            return Config.theme.borderBg;
        case "pane":
            return Config.theme.borderPane;
        case "common":
            return Config.theme.borderCommon;
        case "focus":
            return Config.theme.borderFocus;
        case "primary":
            return Config.theme.borderPrimary;
        case "primaryfocus":
            return Config.theme.borderPrimaryFocus;
        case "overprimary":
            return Config.theme.borderOverPrimary;
        case "secondary":
            return Config.theme.borderSecondary;
        case "secondaryfocus":
            return Config.theme.borderSecondaryFocus;
        case "oversecondary":
            return Config.theme.borderOverSecondary;
        case "tertiary":
            return Config.theme.borderTertiary;
        case "tertiaryfocus":
            return Config.theme.borderTertiaryFocus;
        case "overtertiary":
            return Config.theme.borderOverTertiary;
        case "error":
            return Config.theme.borderError;
        case "errorfocus":
            return Config.theme.borderErrorFocus;
        case "overerror":
            return Config.theme.borderOverError;
        default:
            return Config.theme.borderCommon;
        }
    }

    readonly property color itemColor: {
        switch (variant) {
        case "bg":
            return Config.resolveColor(Config.theme.itemBg);
        case "pane":
            return Config.resolveColor(Config.theme.itemPane);
        case "common":
            return Config.resolveColor(Config.theme.itemCommon);
        case "focus":
            return Config.resolveColor(Config.theme.itemFocus);
        case "primary":
            return Config.resolveColor(Config.theme.itemPrimary);
        case "primaryfocus":
            return Config.resolveColor(Config.theme.itemPrimaryFocus);
        case "overprimary":
            return Config.resolveColor(Config.theme.itemOverPrimary);
        case "secondary":
            return Config.resolveColor(Config.theme.itemSecondary);
        case "secondaryfocus":
            return Config.resolveColor(Config.theme.itemSecondaryFocus);
        case "oversecondary":
            return Config.resolveColor(Config.theme.itemOverSecondary);
        case "tertiary":
            return Config.resolveColor(Config.theme.itemTertiary);
        case "tertiaryfocus":
            return Config.resolveColor(Config.theme.itemTertiaryFocus);
        case "overtertiary":
            return Config.resolveColor(Config.theme.itemOverTertiary);
        case "error":
            return Config.resolveColor(Config.theme.itemError);
        case "errorfocus":
            return Config.resolveColor(Config.theme.itemErrorFocus);
        case "overerror":
            return Config.resolveColor(Config.theme.itemOverError);
        default:
            return Config.resolveColor(Config.theme.itemCommon);
        }
    }

    radius: Config.roundness
    color: "transparent"

    // Gradiente source - con stretch completo
    Item {
        id: gradientSource
        anchors.fill: parent
        anchors.margins: 0
        layer.enabled: true

        // Linear gradient
        Rectangle {
            // Expandir el rectángulo para cubrir completamente el área incluso rotado
            readonly property real diagonal: Math.sqrt(parent.width * parent.width + parent.height * parent.height)
            width: diagonal
            height: diagonal
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2
            visible: gradientType === "linear"
            rotation: gradientAngle
            transformOrigin: Item.Center
            gradient: Gradient {
                orientation: gradientOrientation === "horizontal" ? Gradient.Horizontal : Gradient.Vertical

                GradientStop {
                    property var stopData: gradientStops[0] || ["surface", 0.0]
                    position: stopData[1]
                    color: Config.resolveColor(stopData[0])
                }

                GradientStop {
                    property var stopData: gradientStops[1] || gradientStops[gradientStops.length - 1]
                    position: stopData[1]
                    color: Config.resolveColor(stopData[0])
                }

                GradientStop {
                    property var stopData: gradientStops[2] || gradientStops[gradientStops.length - 1]
                    position: stopData[1]
                    color: Config.resolveColor(stopData[0])
                }

                GradientStop {
                    property var stopData: gradientStops[3] || gradientStops[gradientStops.length - 1]
                    position: stopData[1]
                    color: Config.resolveColor(stopData[0])
                }

                GradientStop {
                    property var stopData: gradientStops[4] || gradientStops[gradientStops.length - 1]
                    position: stopData[1]
                    color: Config.resolveColor(stopData[0])
                }
            }
        }

        // Radial gradient
        Shape {
            id: radialShape
            readonly property real maxDim: Math.max(parent.width, parent.height)
            width: maxDim + 2
            height: maxDim + 2
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2
            visible: gradientType === "radial"
            layer.enabled: true
            layer.smooth: true

            transform: Scale {
                xScale: radialShape.parent.width / radialShape.maxDim
                yScale: radialShape.parent.height / radialShape.maxDim
                origin.x: radialShape.width / 2
                origin.y: radialShape.height / 2
            }

            ShapePath {
                fillGradient: RadialGradient {
                    centerX: radialShape.width * gradientCenterX
                    centerY: radialShape.height * gradientCenterY
                    centerRadius: radialShape.maxDim
                    focalX: centerX
                    focalY: centerY

                    GradientStop {
                        property var stopData: gradientStops[0] || ["surface", 0.0]
                        position: stopData[1]
                        color: Config.resolveColor(stopData[0])
                    }

                    GradientStop {
                        property var stopData: gradientStops[1] || gradientStops[gradientStops.length - 1]
                        position: stopData[1]
                        color: Config.resolveColor(stopData[0])
                    }

                    GradientStop {
                        property var stopData: gradientStops[2] || gradientStops[gradientStops.length - 1]
                        position: stopData[1]
                        color: Config.resolveColor(stopData[0])
                    }

                    GradientStop {
                        property var stopData: gradientStops[3] || gradientStops[gradientStops.length - 1]
                        position: stopData[1]
                        color: Config.resolveColor(stopData[0])
                    }

                    GradientStop {
                        property var stopData: gradientStops[4] || gradientStops[gradientStops.length - 1]
                        position: stopData[1]
                        color: Config.resolveColor(stopData[0])
                    }
                }

                startX: 0
                startY: 0

                PathLine {
                    x: radialShape.width
                    y: 0
                }
                PathLine {
                    x: radialShape.width
                    y: radialShape.height
                }
                PathLine {
                    x: 0
                    y: radialShape.height
                }
                PathLine {
                    x: 0
                    y: 0
                }
            }
        }
    }

    // Máscara con el radio correcto
    Rectangle {
        id: maskRect
        anchors.fill: parent
        radius: root.radius
        color: "white"
        visible: false
        layer.enabled: true
    }

    // Aplicar gradiente con máscara
    MultiEffect {
        anchors.fill: parent
        source: gradientSource
        maskEnabled: true
        maskSource: maskRect
        maskThresholdMin: 0.5
        maskSpreadAtMin: 0.0
    }

    // Shadow effect
    layer.enabled: enableShadow
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowHorizontalOffset: Config.theme.shadowXOffset
        shadowVerticalOffset: Config.theme.shadowYOffset
        shadowBlur: Config.theme.shadowBlur
        shadowColor: Config.resolveColor(Config.theme.shadowColor)
        shadowOpacity: Config.theme.shadowOpacity
    }

    // Border overlay to avoid ClippingRectangle artifacts
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.color: Config.resolveColor(borderData[0])
        border.width: borderData[1]
    }
}
