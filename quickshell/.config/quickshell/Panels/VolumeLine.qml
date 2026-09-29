import QtQuick
import qs.Commons
import qs.Bar

// One volume: a mute button, the slider and the level, on one line.
// `node` is a Pipewire node with `audio`.
Item {
    id: v
    property var node: null
    property bool input: false
    readonly property bool muted: node && node.audio ? node.audio.muted : false
    readonly property real level: node && node.audio ? node.audio.volume : 0
    width: parent.width
    height: 32
    IconButton {
        id: mute
        anchors.left: parent.left; anchors.leftMargin: 6; anchors.verticalCenter: parent.verticalCenter
        icon: v.input ? (v.muted ? "mic_off" : "mic") : (v.muted ? "volume_off" : "volume_up")
        active: v.muted
        onClicked: if (v.node && v.node.audio) v.node.audio.muted = !v.node.audio.muted
    }
    Slider {
        anchors.left: mute.right; anchors.leftMargin: 8
        anchors.right: pct.left; anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: undefined
        value: v.level; dimmed: v.muted
        onMoved: (x) => { if (v.node && v.node.audio) { v.node.audio.volume = x; if (x > 0 && v.node.audio.muted) v.node.audio.muted = false } }
    }
    Label {
        id: pct
        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
        width: 38; horizontalAlignment: Text.AlignRight
        text: v.node ? Math.round(v.level * 100) + "%" : "—"
        font.pixelSize: Theme.fs(12); color: v.muted ? Theme.c.accentDim : Theme.c.accentLight
    }
}
