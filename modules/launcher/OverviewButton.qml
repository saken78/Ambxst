import QtQuick
import qs.modules.globals
import qs.config

ToggleButton {
    buttonIcon: Configuration.bar.overviewIcon
    tooltipText: "Open Window Overview"

    onToggle: function () {
        if (GlobalStates.overviewOpen) {
            GlobalStates.overviewOpen = false;
        } else {
            GlobalStates.dashboardOpen = false;
            GlobalStates.launcherOpen = false;
            GlobalStates.overviewOpen = true;
        }
    }
}
