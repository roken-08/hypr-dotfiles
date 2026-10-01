import QtQuick
import qs.Commons
import qs.Bar

// What a panel shows when it has nothing to list: an icon, a line, a hint.
Item {
    id: e
    property string icon: "inbox"
    property string text: ""
    property string hint: ""
    width: parent.width
    height: col.implicitHeight + 28
    Column {
        id: col
        anchors.centerIn: parent
        spacing: 6
        Icon { anchors.horizontalCenter: parent.horizontalCenter; icon: e.icon; size: Theme.fs(26); color: Theme.c.accentDim }
        Label { anchors.horizontalCenter: parent.horizontalCenter; text: e.text; font.pixelSize: Theme.fs(12.5); color: Theme.c.accentLight }
        Label { anchors.horizontalCenter: parent.horizontalCenter; visible: e.hint !== ""; text: e.hint
                font.pixelSize: Theme.fs(11); color: Theme.c.accentMid; horizontalAlignment: Text.AlignHCenter
                width: Math.min(implicitWidth, e.width - 24); wrapMode: Text.WordWrap }
    }
}
