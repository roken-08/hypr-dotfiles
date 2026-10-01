import QtQuick
import qs.Commons
import qs.Bar

// A panel's title line: the title, an optional detail after it ("· 3"),
// actions (IconButtons) and an optional switch at the right.
Item {
    id: h
    property string title: ""
    property string detail: ""
    property alias toggle: sw
    property bool showToggle: false
    property alias actions: act.data      // actions: [ IconButton { … } ]
    signal toggled(bool on)
    width: parent.width
    height: 28
    Row {
        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        Label { anchors.verticalCenter: parent.verticalCenter; text: h.title; font.pixelSize: Theme.fs(14)
                font.weight: Font.DemiBold; color: Theme.c.accentBright }
        Label { anchors.verticalCenter: parent.verticalCenter; visible: h.detail !== ""; text: h.detail
                font.pixelSize: Theme.fs(12); color: Theme.c.accentMid }
    }
    Row {
        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
        spacing: 6
        Row { id: act; anchors.verticalCenter: parent.verticalCenter; spacing: 2 }
        Toggle {
            id: sw
            anchors.verticalCenter: parent.verticalCenter
            visible: h.showToggle
            onToggled: (on) => h.toggled(on)
        }
    }
}
