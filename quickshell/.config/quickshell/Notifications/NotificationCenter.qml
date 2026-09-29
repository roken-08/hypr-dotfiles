import QtQuick
import Quickshell
import qs.Commons
import qs.Bar
import qs.Panels
import qs.Services

// The bell's panel: the history, grouped by app (newest group first), with
// do not disturb and clear all in the header.
Panel {
    id: p
    name: "notifications"
    panelWidth: 380

    // [{ app, items: [...] }] in the order apps last notified
    readonly property var groups: {
        const out = [], at = {}
        for (const e of Notifs.items) {
            const app = (e.n && e.n.appName) || "Other"
            if (at[app] === undefined) { at[app] = out.length; out.push({ app: app, items: [] }) }
            out[at[app]].items.push(e)
        }
        return out
    }

    PanelHeader {
        title: "Notifications"
        detail: Notifs.count > 0 ? String(Notifs.count) : ""
        actions: [
            IconButton { icon: Notifs.dnd ? "notifications_off" : "notifications"; active: Notifs.dnd; onClicked: Notifs.dnd = !Notifs.dnd },
            IconButton { visible: Notifs.count > 0; icon: "clear_all"; onClicked: Notifs.clearAll() }
        ]
    }
    Label {
        visible: Notifs.dnd
        text: "Do not disturb is on: new notifications wait here quietly"
        font.pixelSize: Theme.fs(11); color: Theme.c.accentMid; width: parent.width; wrapMode: Text.WordWrap
    }

    EmptyState {
        visible: Notifs.count === 0
        icon: Notifs.dnd ? "notifications_off" : "notifications"
        text: "You're all caught up"
        hint: "New notifications show up here"
    }

    Flickable {
        visible: Notifs.count > 0
        width: parent.width
        height: Math.min(list.implicitHeight, 540)
        contentHeight: list.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        Column {
            id: list
            width: parent.width
            spacing: 12
            Repeater {
                model: p.groups
                Column {
                    required property var modelData
                    width: list.width
                    spacing: 6
                    PanelSection { text: modelData.app; detail: modelData.items.length > 1 ? String(modelData.items.length) : "" }
                    Repeater {
                        model: modelData.items
                        NotificationCard { required property var modelData; entry: modelData; showApp: false }
                    }
                }
            }
        }
    }
}
