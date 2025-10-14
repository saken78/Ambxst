import QtQuick
import QtQuick.Effects
import qs.modules.theme
import qs.config

MultiEffect {
    shadowEnabled: true
    shadowHorizontalOffset: 0
    shadowVerticalOffset: 2
    shadowBlur: 0.5
    shadowColor: Colors[Config.theme.shadowColor] || Colors.shadow
    shadowOpacity: 1
}
