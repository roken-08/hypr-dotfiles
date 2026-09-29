import QtQuick
import qs.Commons

// A switch. `on` is what it shows; `toggled(want)` is what the user asked for.
Rectangle {
    id: t
    property bool on: false
    signal toggled(bool want)
    width: 36; height: 20; radius: 10
    color: on ? Theme.c.accentBright : Theme.c.bg3
    Behavior on color { ColorAnimation { duration: Motion.fadeMs } }
    Rectangle {
        width: 14; height: 14; radius: 7
        y: 3; x: t.on ? t.width - width - 3 : 3
        color: t.on ? Theme.c.bg0 : Theme.c.accentMid
        Behavior on x { NumberAnimation { duration: Motion.moveMs; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.moveCurve } }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: t.toggled(!t.on) }
}
