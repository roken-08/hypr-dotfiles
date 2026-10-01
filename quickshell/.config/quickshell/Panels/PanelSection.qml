import QtQuick
import qs.Commons
import qs.Bar

// A section label inside a panel: small capitals, quiet colour.
Item {
    id: s
    property string text: ""
    property string detail: ""        // right-aligned, e.g. "70%"
    width: parent.width
    height: 18
    Label {
        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
        text: s.text.toUpperCase(); font.pixelSize: Theme.fs(10.5); font.weight: Font.DemiBold
        font.letterSpacing: 1.2; color: Theme.c.accentMid
    }
    Label {
        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
        visible: s.detail !== ""; text: s.detail; font.pixelSize: Theme.fs(11); color: Theme.c.accentMid
    }
}
