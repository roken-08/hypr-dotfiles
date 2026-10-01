import QtQuick
import qs.Commons
import qs.Bar

// One control, several choices (power profiles): options = [{ label, icon,
// value, ok }], `current` is the chosen value, `picked(value)` the ask.
Rectangle {
    id: seg
    property var options: []
    property var current: null
    signal picked(var value)
    // the widest label, measured, decides whether the icons fit
    TextMetrics { id: tm; font.family: Theme.font; font.pixelSize: Theme.fs(12); font.weight: Font.DemiBold
                  text: seg.options.reduce((a, o) => o.label.length > a.length ? o.label : a, "") }
    readonly property real cellW: options.length ? (width - 6 - (options.length - 1) * 3) / options.length : 0
    readonly property bool roomy: tm.width + Theme.fs(15) + 6 + 16 <= cellW
    width: parent.width
    height: 34
    radius: Theme.radius
    color: Theme.c.bg1
    border.width: 1; border.color: Theme.c.border
    Row {
        anchors.fill: parent; anchors.margins: 3
        spacing: 3
        Repeater {
            model: seg.options
            Rectangle {
                id: o
                required property var modelData
                readonly property bool sel: modelData.value === seg.current
                readonly property bool ok: modelData.ok !== false
                width: (parent.width - (seg.options.length - 1) * 3) / seg.options.length
                height: parent.height
                radius: Math.max(0, Theme.radius - 1)
                color: sel ? Theme.alpha(Theme.c.accentBright, 0.16) : om.containsMouse && ok ? Theme.c.bg2 : "transparent"
                border.width: sel ? 1 : 0; border.color: Theme.alpha(Theme.c.accentBright, 0.45)
                opacity: ok ? 1 : 0.4
                Behavior on color { ColorAnimation { duration: Motion.fadeMs } }
                // icons on every choice or on none: only when each label fits with one
                readonly property bool roomy: seg.roomy
                Row {
                    anchors.centerIn: parent; spacing: 6
                    Icon { anchors.verticalCenter: parent.verticalCenter; visible: o.modelData.icon !== undefined && o.roomy; icon: o.modelData.icon || ""
                           size: Theme.fs(15); color: o.sel ? Theme.c.accentBright : Theme.c.accentLight }
                    Label { id: ol; anchors.verticalCenter: parent.verticalCenter; text: o.modelData.label; font.pixelSize: Theme.fs(12)
                            font.weight: o.sel ? Font.DemiBold : Font.Normal; color: o.sel ? Theme.c.accentBright : Theme.c.fg }
                }
                MouseArea { id: om; anchors.fill: parent; hoverEnabled: true; enabled: o.ok
                            cursorShape: Qt.PointingHandCursor; onClicked: seg.picked(o.modelData.value) }
            }
        }
    }
}
