pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root

    component Notif: QtObject {
        required property int id
        property Notification notification
        property list<var> actions: notification?.actions.map(action => ({
                    "identifier": action.identifier,
                    "text": action.text
                })) ?? []
        property bool popup: false
        // Capturar valores inmediatamente para evitar binding issues
        property string appIcon: ""
        property string appName: ""
        property string body: ""
        property string image: ""
        property string summary: ""
        property double time
        property string urgency: "normal"
        property Timer timer
        
        // Inicializar valores cuando se asigna la notification
        onNotificationChanged: {
            if (notification) {
                appIcon = notification.appIcon ?? "";
                appName = notification.appName ?? "";
                body = notification.body ?? "";
                image = notification.image ?? "";
                summary = notification.summary ?? "";
                urgency = notification.urgency.toString() ?? "normal";
            }
        }
    }

    function notifToJSON(notif) {
        return {
            "id": notif.id,
            "actions": notif.actions,
            "appIcon": notif.appIcon,
            "appName": notif.appName,
            "body": notif.body,
            "image": notif.image,
            "summary": notif.summary,
            "time": notif.time,
            "urgency": notif.urgency
        };
    }

    component NotifTimer: Timer {
        required property int id
        property int originalInterval: 5000
        property bool isPaused: false
        property real startTime: Date.now()

        interval: originalInterval
        running: !isPaused

        function pause() {
            if (!isPaused) {
                isPaused = true;
                stop();
            }
        }

        function resume() {
            if (isPaused) {
                isPaused = false;
                interval = originalInterval;
                startTime = Date.now();
                start();
            }
        }

        function triggerTimeout() {
            root.timeoutNotification(id);
            destroy();
        }

        onTriggered: triggerTimeout()

        onRunningChanged: {
            if (running) {
                startTime = Date.now();
            }
        }
    }

    property bool silent: false
    property list<Notif> list: []
    property var popupList: list.filter(notif => notif.popup)
    property bool popupInhibited: silent
    property var latestTimeForApp: ({})

    Component {
        id: notifComponent
        Notif {}
    }
    Component {
        id: notifTimerComponent
        NotifTimer {}
    }

    function stringifyList(list) {
        return JSON.stringify(list.map(notif => notifToJSON(notif)), null, 2);
    }

    onListChanged: {
        // Update latest time for each app
        root.list.forEach(notif => {
            if (!root.latestTimeForApp[notif.appName] || notif.time > root.latestTimeForApp[notif.appName]) {
                root.latestTimeForApp[notif.appName] = Math.max(root.latestTimeForApp[notif.appName] || 0, notif.time);
            }
        });
        // Remove apps that no longer have notifications
        Object.keys(root.latestTimeForApp).forEach(appName => {
            if (!root.list.some(notif => notif.appName === appName)) {
                delete root.latestTimeForApp[appName];
            }
        });
    }

    function appNameListForGroups(groups) {
        return Object.keys(groups).sort((a, b) => {
            // Sort by time, descending
            return groups[b].time - groups[a].time;
        });
    }

    function groupsForList(list) {
        const groups = {};
        list.forEach((notif, index) => {
            // Verificar que la notificación es válida antes de agruparla
            if (!notif || !notif.appName || (!notif.summary && !notif.body)) {
                return;
            }
            
            if (!groups[notif.appName]) {
                groups[notif.appName] = {
                    appName: notif.appName,
                    appIcon: notif.appIcon,
                    notifications: [],
                    time: 0
                };
            }
            groups[notif.appName].notifications.push(notif);
            // Always set to the latest time in the group
            groups[notif.appName].time = latestTimeForApp[notif.appName] || notif.time;
        });

        return groups;
    }

    property var groupsByAppName: groupsForList(root.list)
    property var popupGroupsByAppName: groupsForList(root.popupList)
    property var appNameList: appNameListForGroups(root.groupsByAppName)
    property var popupAppNameList: appNameListForGroups(root.popupGroupsByAppName)

    // Quickshell's notification IDs starts at 1 on each run, while saved notifications
    // can already contain higher IDs. This is for avoiding id collisions
    property int idOffset
    signal initDone
    signal notify(notification: var)
    signal discard(id: var)
    signal discardAll
    signal timeout(id: var)

    NotificationServer {
        id: notifServer
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        bodySupported: true
        imageSupported: true
        keepOnReload: false
        persistenceSupported: true

        onNotification: notification => {
            // Verificar que la notificación tiene contenido válido antes de procesarla
            if (!notification || (!notification.summary && !notification.body)) {
                return;
            }
            
            notification.tracked = true;
            const newNotifObject = notifComponent.createObject(root, {
                "id": notification.id + root.idOffset,
                "notification": notification,
                "time": Date.now()
            });

            // Usar Qt.callLater para evitar race conditions al actualizar la lista
            Qt.callLater(() => {
                root.list = [...root.list, newNotifObject];
            });

            // Popup - ahora se muestra en el notch en lugar de popup window
            if (!root.popupInhibited) {
                newNotifObject.popup = true;
                newNotifObject.timer = notifTimerComponent.createObject(root, {
                    "id": newNotifObject.id,
                    "interval": notification.expireTimeout < 0 ? 5000 : notification.expireTimeout // Aumentado para notch
                });
            }

            root.notify(newNotifObject);
        }
    }

    function discardNotification(id) {
        const index = root.list.findIndex(notif => notif.id === id);
        const notifServerIndex = notifServer.trackedNotifications.values.findIndex(notif => notif.id + root.idOffset === id);
        if (index !== -1) {
            root.list.splice(index, 1);
            triggerListChange();
        }
        if (notifServerIndex !== -1) {
            notifServer.trackedNotifications.values[notifServerIndex].dismiss();
        }
        root.discard(id);
    }

    function discardAllNotifications() {
        root.list = [];
        triggerListChange();
        notifServer.trackedNotifications.values.forEach(notif => {
            notif.dismiss();
        });
        root.discardAll();
    }

    signal timeoutWithAnimation(id: var)

    function timeoutNotification(id) {
        // Primero emitir la señal para que la UI haga animación
        root.timeoutWithAnimation(id);

        // Luego, después de un delay para la animación, quitar del popup
        const timeoutTimer = Qt.createQmlObject(`
            import QtQuick
            Timer {
                interval: 350
                running: true
                repeat: false
                onTriggered: {
                    const index = root.list.findIndex((notif) => notif.id === ${id});
                    if (root.list[index] != null)
                        root.list[index].popup = false;
                    root.timeout(${id});
                    destroy();
                }
            }
        `, root);
    }

    function timeoutAll() {
        root.popupList.forEach(notif => {
            root.timeout(notif.id);
        });
        root.popupList.forEach(notif => {
            notif.popup = false;
        });
    }

    function attemptInvokeAction(id, notifIdentifier) {
        const notifServerIndex = notifServer.trackedNotifications.values.findIndex(notif => notif.id + root.idOffset === id);
        if (notifServerIndex !== -1) {
            const notifServerNotif = notifServer.trackedNotifications.values[notifServerIndex];
            const action = notifServerNotif.actions.find(action => action.identifier === notifIdentifier);
            action.invoke();
        } else {
        }
        root.discardNotification(id);
    }

    function pauseGroupTimers(appName) {
        root.popupList.forEach(notif => {
            if (notif.appName === appName && notif.timer) {
                notif.timer.pause();
            }
        });
    }

    function resumeGroupTimers(appName) {
        root.popupList.forEach(notif => {
            if (notif.appName === appName && notif.timer) {
                notif.timer.resume();
            }
        });
    }

    function pauseAllTimers() {
        root.popupList.forEach(notif => {
            if (notif.timer) {
                notif.timer.pause();
            }
        });
    }

    function resumeAllTimers() {
        root.popupList.forEach(notif => {
            if (notif.timer) {
                notif.timer.resume();
            }
        });
    }

    function triggerListChange() {
        root.list = root.list.slice(0);
    }

    Component.onCompleted: {
        root.idOffset = 0;
        root.initDone();
    }
}
