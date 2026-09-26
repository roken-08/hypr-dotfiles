import QtQuick
import qs.Commons
import qs.Services
import qs.Panels
import qs.Notifications

Pill {
    id: bell
    extraRight: pillMode ? 1 : 0     // Qt draws the glyph ~1px narrower than GTK did
    onClicked: Panels.toggle("notifications", bell)
    onRightClicked: Notifs.toggleDnd()
    Icon {
        icon: Notifs.dnd ? (Notifs.count > 0 ? "notifications_paused" : "notifications_off") : (Notifs.count > 0 ? "notifications_unread" : "notifications")
        fill: Notifs.count > 0
        color: Notifs.dnd ? Theme.c.accentDim : Theme.c.accentLight
    }
    NotificationCenter { anchorItem: bell }
}
