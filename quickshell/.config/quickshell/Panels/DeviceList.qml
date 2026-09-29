import QtQuick
import qs.Commons
import qs.Bar

// A device picker that stays short: the current device, and the others
// behind a "N more" row. `model` = the devices, `current` = the chosen one,
// `icon(dev)` / `label(dev)` describe one, `picked(dev)` asks to switch.
Column {
    id: d
    property var model: []
    property var current: null
    property var icon: (dev) => "speaker"
    property var label: (dev) => String(dev)
    property bool expanded: false
    signal picked(var dev)
    width: parent.width
    spacing: 2
    readonly property var others: model.filter(x => x !== current)

    PanelRow {
        visible: d.current !== null
        icon: d.current ? d.icon(d.current) : ""
        title: d.current ? d.label(d.current) : ""
        active: true
        onClicked: if (d.others.length) d.expanded = !d.expanded
    }
    PanelRow {
        visible: d.others.length > 0
        icon: d.expanded ? "expand_less" : "expand_more"
        title: d.expanded ? "Fewer devices" : d.others.length + (d.others.length === 1 ? " more device" : " more devices")
        check: false
        onClicked: d.expanded = !d.expanded
    }
    Column {
        width: parent.width; spacing: 2
        visible: d.expanded
        Repeater {
            model: d.expanded ? d.others : []
            PanelRow {
                required property var modelData
                icon: d.icon(modelData)
                title: d.label(modelData)
                onClicked: { d.picked(modelData); d.expanded = false }
            }
        }
    }
}
