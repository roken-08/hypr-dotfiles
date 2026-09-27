import QtQuick
import qs.Commons
import qs.Bar

// Small pill button for panel footers / action rows.
Rectangle {
    id: b
    property string text: ""
    property string icon: ""
    property bool primary: false
    signal clicked()
    implicitWidth: row.implicitWidth + 24
    // tighter when a row gives the button less room than it asks for (the
    // power panel's four session buttons), so the text never meets the edge
    readonly property bool tight: width < bi.implicitWidth + bl.implicitWidth + 8 + 20
    implicitHeight: 30
    radius: Theme.radius
    color: primary ? (m.containsMouse ? Theme.c.accentLight : Theme.c.fg) : (m.containsMouse ? Theme.c.bg3 : Theme.c.bg2)
    border.width: primary ? 0 : 1
    border.color: m.containsMouse ? Theme.c.borderStrong : Theme.c.border
    Behavior on color { ColorAnimation { duration: 120 } }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: b.tight ? 4 : 8
        Icon { id: bi; visible: b.icon !== ""; icon: b.icon; size: material ? Theme.fs(17) : Theme.fs(14); color: b.primary ? Theme.c.bg0 : Theme.c.accentLight }
        Label { id: bl; visible: b.text !== ""; text: b.text; font.pixelSize: Theme.fs(12); color: b.primary ? Theme.c.bg0 : Theme.c.fg }
    }
    MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: b.clicked() }
}
