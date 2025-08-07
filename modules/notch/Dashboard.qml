import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import qs.modules.theme
import qs.modules.globals
import qs.config

NotchAnimationBehavior {
    id: root

    property var state: QtObject {
        property int currentTab: 0
    }

    readonly property var tabModel: ["Widgets", "Pins", "Kanban", "Wallpapers"]
    readonly property int tabCount: tabModel.length
    readonly property int tabSpacing: 8

    readonly property real nonAnimWidth: 400 + viewWrapper.anchors.margins * 2

    implicitWidth: nonAnimWidth
    implicitHeight: mainLayout.implicitHeight

    // Usar el comportamiento estándar de animaciones del notch
    isVisible: GlobalStates.dashboardOpen

    Column {
        id: mainLayout
        anchors.fill: parent
        spacing: 8

        // Tab buttons
        Item {
            id: tabsContainer
            width: parent.width
            height: 32

            // Background highlight que se desplaza
            Rectangle {
                id: tabHighlight
                width: (parent.width - root.tabSpacing * (root.tabCount - 1)) / root.tabCount
                height: parent.height
                x: root.state.currentTab * (width + root.tabSpacing)
                y: 0
                color: Qt.rgba(Colors.surfaceContainer.r, Colors.surfaceContainer.g, Colors.surfaceContainer.b, Config.opacity)
                radius: Config.roundness > 0 ? Config.roundness + 4 : 0
                z: 0

                Behavior on x {
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }
            }

            Row {
                id: tabs
                anchors.fill: parent
                spacing: root.tabSpacing

                Repeater {
                    model: root.tabModel

                    Button {
                        required property int index
                        required property string modelData

                        text: modelData
                        flat: true
                        implicitWidth: (tabsContainer.width - root.tabSpacing * (root.tabCount - 1)) / root.tabCount
                        height: tabsContainer.height

                        background: Rectangle {
                            color: "transparent"
                            radius: Config.roundness > 0 ? Config.roundness + 4 : 0
                        }

                        contentItem: Text {
                            text: parent.text
                            color: root.state.currentTab === index ? Colors.adapter.primary : Colors.adapter.overBackground
                            font.family: Styling.defaultFont
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter

                            Behavior on color {
                                ColorAnimation {
                                    duration: Config.animDuration
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        onClicked: root.state.currentTab = index

                        Behavior on scale {
                            NumberAnimation {
                                duration: Config.animDuration / 3
                                easing.type: Easing.OutCubic
                            }
                        }

                        states: State {
                            name: "pressed"
                            when: parent.pressed
                            PropertyChanges {
                                target: parent
                                scale: 0.95
                            }
                        }
                    }
                }
            }
        }

        // Content area
        PaneRect {
            id: viewWrapper

            width: parent.width
            height: parent.height - tabs.height - 8 // Adjust height to fit below tabs

            radius: Config.roundness > 0 ? Config.roundness + 4 : 0
            clip: true

            SwipeView {
                id: view

                anchors.fill: parent

                currentIndex: root.state.currentTab

                onCurrentIndexChanged: {
                    root.state.currentTab = currentIndex;
                }

                // Overview Tab
                DashboardPane {
                    sourceComponent: overviewComponent
                }

                // System Tab
                DashboardPane {
                    sourceComponent: systemComponent
                }

                // Quick Settings Tab
                DashboardPane {
                    sourceComponent: quickSettingsComponent
                }

                // Wallpapers Tab
                DashboardPane {
                    sourceComponent: wallpapersComponent
                }
            }
        }
    }

    // Animated size properties for smooth transitions
    property real animatedWidth: implicitWidth
    property real animatedHeight: implicitHeight

    width: animatedWidth
    height: animatedHeight

    // Update animated properties when implicit properties change
    onImplicitWidthChanged: animatedWidth = implicitWidth
    onImplicitHeightChanged: animatedHeight = implicitHeight

    Behavior on animatedWidth {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutBack
            easing.overshoot: 1.1
        }
    }

    Behavior on animatedHeight {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutBack
            easing.overshoot: 1.1
        }
    }

    // Component definitions for better performance (defined once, reused)
    Component {
        id: overviewComponent
        OverviewTab {}
    }

    Component {
        id: systemComponent
        SystemTab {}
    }

    Component {
        id: quickSettingsComponent
        QuickSettingsTab {}
    }

    Component {
        id: wallpapersComponent
        WallpapersTab {}
    }

    component DashboardPane: Item {
        implicitWidth: 400
        implicitHeight: 300

        property alias sourceComponent: loader.sourceComponent

        Loader {
            id: loader
            anchors.fill: parent
            active: true // Simplificamos: siempre cargar para debugging
        }
    }

    component OverviewTab: Rectangle {
        color: "transparent"
        implicitWidth: 400
        implicitHeight: 300

        Text {
            anchors.centerIn: parent
            text: "Widgets"
            color: Colors.adapter.overSurfaceVariant
            font.family: Styling.defaultFont
            font.pixelSize: 16
            font.weight: Font.Medium
        }
    }

    component SystemTab: Rectangle {
        color: "transparent"
        implicitWidth: 400
        implicitHeight: 300

        Text {
            anchors.centerIn: parent
            text: "Pins"
            color: Colors.adapter.overSurfaceVariant
            font.family: Styling.defaultFont
            font.pixelSize: 16
            font.weight: Font.Medium
        }
    }

    component QuickSettingsTab: Rectangle {
        color: "transparent"
        implicitWidth: 400
        implicitHeight: 300

        Text {
            anchors.centerIn: parent
            text: "Kanban"
            color: Colors.adapter.overSurfaceVariant
            font.family: Styling.defaultFont
            font.pixelSize: 16
            font.weight: Font.Medium
        }
    }

    component WallpapersTab: Rectangle {
        color: "transparent"
        anchors.fill: parent

        property string searchText: ""
        readonly property int gridColumns: 3

        property var filteredWallpapers: {
            if (!GlobalStates.wallpaperManager)
                return [];
            if (searchText.length === 0)
                return GlobalStates.wallpaperManager.wallpaperPaths;

            return GlobalStates.wallpaperManager.wallpaperPaths.filter(function (path) {
                const fileName = path.split('/').pop().toLowerCase();
                return fileName.includes(searchText.toLowerCase());
            });
        }

        Row {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            // Sidebar izquierdo con search y opciones
            Column {
                width: parent.width - wallpaperGridContainer.width - 8  // Expandir para llenar el espacio restante
                height: parent.height + 4
                spacing: 8

                // Barra de búsqueda
                Rectangle {
                    width: parent.width
                    height: 36
                    color: Colors.surfaceContainer
                    radius: Config.roundness > 0 ? Config.roundness : 0
                    border.color: searchInput.activeFocus ? Colors.adapter.primary : Colors.adapter.outline
                    border.width: 2

                    Behavior on border.color {
                        ColorAnimation {
                            duration: Config.animDuration / 2
                            easing.type: Easing.OutCubic
                        }
                    }

                    TextInput {
                        id: searchInput
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        verticalAlignment: TextInput.AlignVCenter
                        text: searchText
                        color: Colors.adapter.overSurfaceVariant
                        font.family: Styling.defaultFont
                        font.pixelSize: 12
                        selectByMouse: true

                        onTextChanged: searchText = text

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "Search wallpapers..."
                            color: Colors.adapter.outline
                            font.family: Styling.defaultFont
                            font.pixelSize: 12
                            visible: !parent.activeFocus && parent.text.length === 0
                        }
                    }
                }

                // Área placeholder para opciones futuras
                Rectangle {
                    width: parent.width
                    height: parent.height - 36 - 12
                    color: Colors.surfaceContainer
                    radius: Config.roundness > 0 ? Config.roundness : 0
                    border.color: Colors.adapter.outline
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Placeholder\nfor future\noptions"
                        color: Colors.adapter.overSurfaceVariant
                        font.family: Styling.defaultFont
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        lineHeight: 1.2
                    }
                }
            }

            // Grid de wallpapers a la derecha
            Rectangle {
                id: wallpaperGridContainer
                width: wallpaperGridContainer.height
                height: parent.height
                color: Colors.surfaceContainer
                radius: Config.roundness > 0 ? Config.roundness : 0
                border.color: Colors.adapter.outline
                border.width: 0
                clip: true

                readonly property int wallpaperHeight: height / 3  // 1/3 de la altura del contenedor
                readonly property int wallpaperWidth: wallpaperHeight  // Mantener cuadrados

                ScrollView {
                    id: scrollView
                    anchors.fill: parent

                    GridView {
                        id: wallpaperGrid
                        width: parent.width
                        cellWidth: wallpaperGridContainer.wallpaperWidth
                        cellHeight: wallpaperGridContainer.wallpaperHeight
                        model: filteredWallpapers

                        delegate: Rectangle {
                            width: wallpaperGridContainer.wallpaperWidth
                            height: wallpaperGridContainer.wallpaperHeight
                            color: Colors.surface
                            border.color: isCurrentWallpaper ? Colors.adapter.primary : "transparent"
                            border.width: isCurrentWallpaper ? 2 : 0

                            property bool isCurrentWallpaper: {
                                if (!GlobalStates.wallpaperManager)
                                    return false;
                                return GlobalStates.wallpaperManager.currentWallpaper === modelData;
                            }

                            Behavior on border.color {
                                ColorAnimation {
                                    duration: Config.animDuration
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Image {
                                anchors.fill: parent
                                source: "file://" + modelData
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                smooth: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onEntered: {
                                    if (!parent.isCurrentWallpaper) {
                                        parent.color = Colors.surfaceContainerHigh;
                                    }
                                }
                                onExited: {
                                    if (!parent.isCurrentWallpaper) {
                                        parent.color = Colors.surface;
                                    }
                                }
                                onPressed: parent.scale = 0.95
                                onReleased: parent.scale = 1.0

                                onClicked: {
                                    if (GlobalStates.wallpaperManager) {
                                        GlobalStates.wallpaperManager.setWallpaper(modelData);
                                    }
                                }
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: Config.animDuration / 2
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Behavior on scale {
                                NumberAnimation {
                                    duration: Config.animDuration / 3
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
