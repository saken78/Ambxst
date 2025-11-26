pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import qs.modules.theme
import qs.config

Rectangle {
    id: root

    required property string variant

    property string gradientOrientation: "vertical"
    property bool enableShadow: false

    readonly property var gradientStops: {
        switch (variant) {
            case "bg": return Config.theme.gradBg
            case "pane": return Config.theme.gradPane
            case "common": return Config.theme.gradCommon
            case "focus": return Config.theme.gradFocus
            case "primary": return Config.theme.gradPrimary
            case "primaryfocus": return Config.theme.gradPrimaryFocus
            case "overprimary": return Config.theme.gradOverPrimary
            case "secondary": return Config.theme.gradSecondary
            case "secondaryfocus": return Config.theme.gradSecondaryFocus
            case "oversecondary": return Config.theme.gradOverSecondary
            case "tertiary": return Config.theme.gradTertiary
            case "tertiaryfocus": return Config.theme.gradTertiaryFocus
            case "overtertiary": return Config.theme.gradOverTertiary
            case "error": return Config.theme.gradError
            case "errorfocus": return Config.theme.gradErrorFocus
            case "overerror": return Config.theme.gradOverError
            default: return Config.theme.gradCommon
        }
    }

    readonly property var borderData: {
        switch (variant) {
            case "bg": return Config.theme.borderBg
            case "pane": return Config.theme.borderPane
            case "common": return Config.theme.borderCommon
            case "focus": return Config.theme.borderFocus
            case "primary": return Config.theme.borderPrimary
            case "primaryfocus": return Config.theme.borderPrimaryFocus
            case "overprimary": return Config.theme.borderOverPrimary
            case "secondary": return Config.theme.borderSecondary
            case "secondaryfocus": return Config.theme.borderSecondaryFocus
            case "oversecondary": return Config.theme.borderOverSecondary
            case "tertiary": return Config.theme.borderTertiary
            case "tertiaryfocus": return Config.theme.borderTertiaryFocus
            case "overtertiary": return Config.theme.borderOverTertiary
            case "error": return Config.theme.borderError
            case "errorfocus": return Config.theme.borderErrorFocus
            case "overerror": return Config.theme.borderOverError
            default: return Config.theme.borderCommon
        }
    }

    readonly property color itemColor: {
        switch (variant) {
            case "bg": return Config.resolveColor(Config.theme.itemBg)
            case "pane": return Config.resolveColor(Config.theme.itemPane)
            case "common": return Config.resolveColor(Config.theme.itemCommon)
            case "focus": return Config.resolveColor(Config.theme.itemFocus)
            case "primary": return Config.resolveColor(Config.theme.itemPrimary)
            case "primaryfocus": return Config.resolveColor(Config.theme.itemPrimaryFocus)
            case "overprimary": return Config.resolveColor(Config.theme.itemOverPrimary)
            case "secondary": return Config.resolveColor(Config.theme.itemSecondary)
            case "secondaryfocus": return Config.resolveColor(Config.theme.itemSecondaryFocus)
            case "oversecondary": return Config.resolveColor(Config.theme.itemOverSecondary)
            case "tertiary": return Config.resolveColor(Config.theme.itemTertiary)
            case "tertiaryfocus": return Config.resolveColor(Config.theme.itemTertiaryFocus)
            case "overtertiary": return Config.resolveColor(Config.theme.itemOverTertiary)
            case "error": return Config.resolveColor(Config.theme.itemError)
            case "errorfocus": return Config.resolveColor(Config.theme.itemErrorFocus)
            case "overerror": return Config.resolveColor(Config.theme.itemOverError)
            default: return Config.resolveColor(Config.theme.itemCommon)
        }
    }

    radius: Config.roundness
    border.color: Config.resolveColor(borderData[0])
    border.width: borderData[1]

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

    layer.enabled: enableShadow
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowHorizontalOffset: Config.theme.shadowXOffset
        shadowVerticalOffset: Config.theme.shadowYOffset
        shadowBlur: Config.theme.shadowBlur
        shadowColor: Config.resolveColor(Config.theme.shadowColor)
        shadowOpacity: Config.theme.shadowOpacity
    }
}
