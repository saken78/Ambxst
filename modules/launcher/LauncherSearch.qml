import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"
import "../../services"

Rectangle {
    id: root

    property string searchText: ""
    property bool showResults: searchText.length > 0
    signal itemSelected

    implicitWidth: 500
    implicitHeight: mainLayout.implicitHeight + 16
    color: Colors.surface
    radius: 24
    border.color: Colors.outline
    border.width: 0

    Behavior on height {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutQuart
        }
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        // Search input
        Rectangle {
            id: searchInputContainer
            Layout.fillWidth: true
            implicitHeight: 48
            color: Colors.surfaceContainerLowest
            radius: 16
            border.color: searchInput.activeFocus ? Colors.primary : Colors.outline
            border.width: 0

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                Text {
                    text: ""
                    font.pixelSize: 20
                    color: Colors.primary
                }

                TextField {
                    id: searchInput
                    Layout.fillWidth: true
                    placeholderText: "Search applications..."
                    placeholderTextColor: Colors.surfaceBright
                    font.pixelSize: 14
                    color: Colors.foreground
                    background: null

                    onTextChanged: root.searchText = text

                    onAccepted: {
                        if (resultsList.count > 0) {
                            let firstItem = resultsList.itemAtIndex(0);
                            if (firstItem) {
                                firstItem.clicked();
                            }
                        }
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            root.itemSelected();
                        } else if (event.key === Qt.Key_Down && resultsList.count > 0) {
                            resultsList.forceActiveFocus();
                            resultsList.currentIndex = 0;
                        }
                    }
                }
            }
        }

        // Results list
        ListView {
            id: resultsList
            Layout.fillWidth: true
            Layout.preferredHeight: 5 * 48
            visible: true
            clip: true

            model: root.searchText.length > 0 ? AppSearch.fuzzyQuery(root.searchText) : AppSearch.getAllApps()

            delegate: Rectangle {
                required property var modelData

                width: resultsList.width
                height: 48
                color: mouseArea.containsMouse ? Colors.surfaceVariant : "transparent"
                radius: 16

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: {
                        modelData.execute();
                        root.itemSelected();
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 12

                    Image {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        source: "image://icon/" + modelData.icon
                        fillMode: Image.PreserveAspectFit

                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            border.color: Colors.outline
                            border.width: parent.status === Image.Error ? 1 : 0
                            radius: 4

                            Text {
                                anchors.centerIn: parent
                                text: "?"
                                visible: parent.parent.status === Image.Error
                                color: Colors.foreground
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData.name
                        color: Colors.foreground
                        font.pixelSize: 14
                        elide: Text.ElideRight
                    }
                }
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    if (currentItem) {
                        let currentData = model[currentIndex];
                        if (currentData) {
                            currentData.execute();
                            root.itemSelected();
                        }
                    }
                } else if (event.key === Qt.Key_Escape) {
                    searchInput.forceActiveFocus();
                } else if (event.key === Qt.Key_Up && currentIndex === 0) {
                    searchInput.forceActiveFocus();
                }
            }

            highlight: Rectangle {
                color: Colors.surfaceBright
                radius: 16
            }
        }
    }

    Component.onCompleted: {
        searchInput.forceActiveFocus();
    }
}
