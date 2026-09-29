import QtQuick
import qs.Commons

// A square icon-only button: mute, refresh, clear, close. `active` shows a
// toggled state (the accent) without changing the icon.
Rectangle {
    id: b
    property string icon: ""
    property bool active: false
    property bool danger: false
    property real iconSize: Theme.fs(16)
    signal clicked()
    width: 28; height: 28
    radius: Theme.radius
    color: active ? Theme.alpha(Theme.c.accentBright, 0.16) : m.containsMouse ? Theme.c.bg2 : "transparent"
    Behavior on color { ColorAnimation { duration: Motion.fadeMs } }
    Icon {
        anchors.centerIn: parent
        icon: b.icon; size: b.iconSize
        color: b.danger && m.containsMouse && Theme.hued ? Theme.c.critical
             : b.active ? Theme.c.accentBright : m.containsMouse ? Theme.c.fg : Theme.c.accentLight
    }
    MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: b.clicked() }
}
