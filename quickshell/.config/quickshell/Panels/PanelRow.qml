import QtQuick
import qs.Commons
import qs.Bar

// A list row: an icon in a small chip, a title, an optional subtitle and
// trailing text. `active` marks the selected / connected one: accent chip and
// title, and a check at the end, instead of a filled row.
Rectangle {
    id: r
    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property string trailing: ""
    property string trailingIcon: ""    // an Icon name, drawn after the trailing text
    property bool active: false
    property bool busy: false
    property bool check: true           // show the check on the active row
    property bool dim: false            // unavailable or offline
    property real strength: -1          // 0..1: signal bars in the chip instead of the icon
    signal clicked()
    signal rightClicked()
    width: parent.width
    height: subtitle !== "" ? 48 : 40
    radius: Theme.radius
    color: m.containsMouse ? Theme.c.bg1 : "transparent"
    opacity: dim ? 0.55 : 1
    Behavior on color { ColorAnimation { duration: Motion.fadeMs } }

    Rectangle {
        id: chip
        x: 6; anchors.verticalCenter: parent.verticalCenter
        width: 28; height: 28
        radius: Math.max(0, Theme.radius)
        color: r.active ? Theme.alpha(Theme.c.accentBright, 0.16) : Theme.c.bg2
        Behavior on color { ColorAnimation { duration: Motion.fadeMs } }
        Icon {
            anchors.centerIn: parent
            visible: r.strength < 0
            icon: r.icon; size: material ? Theme.fs(16) : Theme.fs(14)
            color: r.active ? Theme.c.accentBright : Theme.c.accentLight
        }
        Row {
            anchors.centerIn: parent
            visible: r.strength >= 0
            spacing: 2
            readonly property int lit: r.strength < 0 ? 0 : Math.max(1, Math.ceil(r.strength * 4))
            Repeater {
                model: 4
                Rectangle {
                    required property int index
                    anchors.bottom: parent.bottom
                    width: 3; height: 4 + index * 3; radius: 1
                    color: index < parent.lit ? (r.active ? Theme.c.accentBright : Theme.c.accentLight) : Theme.c.bg4
                }
            }
            height: 13
        }
    }
    Column {
        anchors.left: chip.right; anchors.leftMargin: 10
        anchors.right: tr.left; anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        Label { width: parent.width; elide: Text.ElideRight; text: r.title; font.pixelSize: Theme.fs(13)
                color: r.active ? Theme.c.accentBright : Theme.c.fg; font.weight: r.active ? Font.DemiBold : Font.Normal }
        Label { visible: r.subtitle !== ""; width: parent.width; elide: Text.ElideRight; text: r.subtitle
                font.pixelSize: Theme.fs(11); color: Theme.c.accentMid }
    }
    Row {
        id: tr
        anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
        spacing: 6
        Label { anchors.verticalCenter: parent.verticalCenter; visible: text !== "" && !r.busy; text: r.trailing
                font.pixelSize: Theme.fs(11); color: Theme.c.accentMid }
        Icon { anchors.verticalCenter: parent.verticalCenter; visible: !r.busy && r.trailingIcon !== ""; icon: r.trailingIcon
               size: Theme.fs(14); color: Theme.c.accentMid }
        Icon {
            anchors.verticalCenter: parent.verticalCenter
            visible: r.busy; icon: "refresh"; size: Theme.fs(15); color: Theme.c.accentMid
            RotationAnimation on rotation { running: r.busy; from: 0; to: 360; duration: 900; loops: Animation.Infinite }
        }
        Icon { anchors.verticalCenter: parent.verticalCenter; visible: r.active && r.check && !r.busy; icon: "check"
               size: Theme.fs(16); color: Theme.c.accentBright }
    }
    MouseArea {
        id: m
        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (e) => e.button === Qt.RightButton ? r.rightClicked() : r.clicked()
    }
}
