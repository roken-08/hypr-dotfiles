import QtQuick
import qs.Commons
import qs.Services

// One bar module. Draws itself as a bordered pill in the "pill" skin
// (the classic waybar look) and as flat text in "minimal". Widgets put
// their content inside; clicks/scroll come out as signals.
Rectangle {
    id: pill
    default property alias content: inner.data
    property bool pillMode: Theme.barStyle === "pill"
    property bool hovered: mouse.containsMouse
    property bool interactive: true
    property int padH: pillMode ? 9 : 4   // minimal: widgets sit close, a small gap apart
    property int padV: pillMode ? 2 : 0
    property bool round: false        // the tray pill in the classic look
    property int extraRight: 0        // waybar reserves room after an ellipsized label

    signal clicked()
    signal rightClicked()
    signal middleClicked()
    signal scrolled(int delta)

    readonly property bool vertical: Config.vertical
    implicitWidth: vertical ? (pillMode ? 34 : 28) : inner.implicitWidth + padH * 2 + extraRight
    implicitHeight: vertical ? inner.implicitHeight + (pillMode ? 14 : 8) : (pillMode ? 31 : 26)
    // pill skin keeps the waybar css values exactly (6px, 12px tray, bg3 border)
    radius: pillMode ? (round ? 12 : 6) : Theme.radius
    // while its panel is out, a Legacy pill is the drawer's tab: square on the
    // side the panel hangs from, in the panel's colour (Panels/Panel.qml)
    readonly property bool attached: pillMode && (Panels.item === pill || Panels.closing === pill)
    readonly property string side: Config.position
    topLeftRadius:     attached && (side === "bottom" || side === "right") ? 0 : radius
    topRightRadius:    attached && (side === "bottom" || side === "left")  ? 0 : radius
    bottomLeftRadius:  attached && (side === "top"    || side === "right") ? 0 : radius
    bottomRightRadius: attached && (side === "top"    || side === "left")  ? 0 : radius
    color: attached ? Theme.c.bg0
         : pillMode ? (hovered && interactive ? Theme.c.bg2 : Theme.c.bg0)
                    : (hovered && interactive ? Theme.c.bg2 : "transparent")
    border.width: pillMode ? 1 : 0
    border.color: attached ? Theme.c.bg3
                : pillMode ? (hovered && interactive ? Theme.c.bg4 : Theme.c.bg3)
                           : (hovered && interactive ? Theme.c.borderStrong : Theme.c.border)
    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    property int gap: pillMode ? 13 : 4   // icon to its text (pill: measured against waybar)
    Grid {
        id: inner
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: pill.vertical ? parent.horizontalCenter : undefined
        x: pill.vertical ? 0 : pill.padH
        // exactly as many cells as visible children: Grid pads its implicit
        // size with spacing for every declared row/column, used or not
        // (a Repeater is a child too, and a 0x0 one: skip it by what it is,
        // not by size, or items not yet measured go uncounted and the grid
        // gets fewer cells than items: widgets wrapped or overlapped for a frame)
        readonly property int n: {
            let c = 0
            for (let i = 0; i < visibleChildren.length; i++) if (visibleChildren[i].delegate === undefined) c++
            return Math.max(1, c)
        }
        columns: pill.vertical ? 1 : n
        rows: pill.vertical ? n : 1
        spacing: pill.vertical ? 4 : pill.gap
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter
    }

    // below the content (z -1) so children with their own MouseArea (tray
    // icons, player buttons) get their clicks; plain Labels fall through to it
    MouseArea {
        id: mouse
        z: -1
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: pill.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: (e) => {
            if (e.button === Qt.RightButton) pill.rightClicked()
            else if (e.button === Qt.MiddleButton) pill.middleClicked()
            else pill.clicked()
        }
        onWheel: (w) => pill.scrolled(w.angleDelta.y > 0 ? 1 : -1)
    }
}
