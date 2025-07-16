pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell

Singleton {
    property QtObject bar: QtObject {
        property bool bottom: false
        property bool borderless: false
        property string topLeftIcon: "spark"
        property bool showBackground: true
        property bool verbose: true
        property list<string> screenList: []
        property QtObject workspaces: QtObject {
            property int shown: 10
            property bool showAppIcons: true
            property bool alwaysShowNumbers: false
            property int showNumberDelay: 300
        }
    }
}
