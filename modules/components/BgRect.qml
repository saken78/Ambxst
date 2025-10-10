import QtQuick
import Quickshell.Widgets
import qs.modules.theme
import qs.config
import qs.modules.components

Rectangle {
    radius: Config.roundness
    border.color: Colors[Config.theme.borderColor] || Colors.surfaceBright
    border.width: Config.theme.borderSize

    gradient: Gradient {
        id: bgGradient
        orientation: Config.theme.bgOrientation === "horizontal" ? Gradient.Horizontal : Gradient.Vertical
        stops: {
            const result = [];
            for (let i = 0; i < Config.theme.bgColor.length; i++) {
                const item = Config.theme.bgColor[i];
                const colorValue = item[0];
                const position = item[1];
                
                let finalColor;
                if (colorValue.startsWith("#") || colorValue.startsWith("rgba") || colorValue.startsWith("rgb")) {
                    finalColor = colorValue;
                } else {
                    finalColor = Colors[colorValue] || colorValue;
                }
                
                result.push(Qt.createQmlObject(
                    'import QtQuick; GradientStop { position: ' + position + '; color: "' + finalColor + '" }',
                    bgGradient,
                    "gradientStop" + i
                ));
            }
            return result;
        }
    }

    layer.enabled: true
    layer.effect: Shadow {}
}
