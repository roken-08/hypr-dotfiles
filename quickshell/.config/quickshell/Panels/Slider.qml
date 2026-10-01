import QtQuick
import qs.Commons

// Horizontal slider, 0..1. `value` is shown; `moved(v)` is emitted on drag
// and on the scroll wheel (5% a notch).
Item {
    id: s
    property real value: 0
    property bool dimmed: false
    signal moved(real v)
    width: parent.width
    height: 24
    readonly property real v: Math.max(0, Math.min(1, value))
    readonly property bool hot: ma.containsMouse || ma.pressed
    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width; height: 6; radius: 3
        color: Theme.c.bg3
        Rectangle {
            width: Math.max(6, parent.width * s.v); height: parent.height; radius: 3
            color: s.dimmed ? Theme.c.accentDim : Theme.c.accentBright
            Behavior on color { ColorAnimation { duration: Motion.fadeMs } }
        }
    }
    Rectangle {
        readonly property int d: s.hot ? 18 : 16
        width: d; height: d; radius: d / 2
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(s.width - width, s.width * s.v - width / 2))
        color: s.dimmed ? Theme.c.accentMid : Theme.c.fg
        border.width: 2; border.color: Theme.c.bg0
        Behavior on width { NumberAnimation { duration: Motion.fadeMs } }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        function set(mx) { s.moved(Math.max(0, Math.min(1, mx / s.width))) }
        onPressed: (e) => set(e.x)
        onPositionChanged: (e) => { if (pressed) set(e.x) }
        onWheel: (w) => s.moved(Math.max(0, Math.min(1, s.value + (w.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
