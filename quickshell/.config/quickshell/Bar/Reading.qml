import QtQuick
import qs.Commons

// One icon + number reading for a bar widget (sysmon, netspeed). Side by
// side in a horizontal bar, the number keeping the width of `widest` so the
// bar never shifts as it changes; stacked in a smaller size in a side bar,
// which is only 28px wide.
Grid {
    id: r
    property string icon
    property string text
    property string widest: "88%"      // 100% (full load) nudges by one character
    property color color: Theme.c.accentLight
    property color iconColor: color
    readonly property bool vertical: Config.vertical
    columns: vertical ? 1 : 2
    columnSpacing: 3
    rowSpacing: 1
    horizontalItemAlignment: Grid.AlignHCenter
    verticalItemAlignment: Grid.AlignVCenter
    Icon { icon: r.icon; color: r.iconColor; size: r.vertical ? Theme.fs(14) : Theme.fs(15) }
    FixedLabel {
        text: r.text
        widest: r.widest
        color: r.color
        font.pixelSize: r.vertical ? Theme.fs(9) : Theme.fontSize
    }
}
