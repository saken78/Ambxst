//@ pragma UseQApplication
//@ pragma ShellId Ambyst
import QtQuick
import Quickshell
import qs.modules.bar
import qs.modules.bar.workspaces
import qs.modules.notifications
import qs.modules.widgets.dashboard.wallpapers
import qs.modules.notch
import qs.modules.services
import qs.modules.corners
import qs.config

ShellRoot {
    id: root

    Variants {
        model: Quickshell.screens

        Loader {
            id: wallpaperLoader
            active: true
            required property ShellScreen modelData
            sourceComponent: Wallpaper {
                screen: wallpaperLoader.modelData
            }
        }
    }

    Variants {
        model: {
            const screens = Quickshell.screens;
            const list = Config.bar.screenList;
            if (!list || list.length === 0)
                return screens;
            return screens.filter(screen => list.includes(screen.name));
        }

        Loader {
            id: barLoader
            active: true
            required property ShellScreen modelData
            sourceComponent: Bar {
                screen: barLoader.modelData
            }
        }
    }

    Variants {
        model: {
            const screens = Quickshell.screens;
            const list = Config.bar.screenList;
            if (!list || list.length === 0)
                return screens;
            return screens.filter(screen => list.includes(screen.name));
        }

        Loader {
            id: notchLoader
            active: true
            required property ShellScreen modelData
            sourceComponent: NotchWindow {
                screen: notchLoader.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens

        Loader {
            id: cornersLoader
            active: true
            required property ShellScreen modelData
            sourceComponent: ScreenCorners {
                screen: cornersLoader.modelData
            }
        }
    }

    GlobalShortcuts {
        id: globalShortcuts
    }

    HyprlandConfig {
        id: hyprlandConfig
    }
}
