import QtQuick
import qs.Commons
import qs.Services
import qs.Panels

// Agents: the default agent's session usage. Hidden until an agent account
// is found. Click for the panel, right-click launches the default agent.
Pill {
    id: ag
    visible: Agents.present
    readonly property int pct: Agents.session ? Agents.session.percent : -1
    // normal colour while there is quota left; dimmed only once the limit is
    // used up (hued themes warn from 90%)
    readonly property color tone: pct >= 100 ? Theme.c.accentDim
                                : Theme.hued && pct >= 90 ? Theme.c.warning : Theme.c.accentLight
    onClicked: Panels.toggle("agents", ag)
    onRightClicked: Agents.launch("")
    Icon { icon: "󱚝"; size: Theme.fontSize + 1; color: ag.tone }   // the rice's own robot glyph
    FixedLabel { visible: ag.pct >= 0 && !ag.vertical; text: ag.pct + "%"; widest: "88%"; color: ag.tone }
    AgentsPanel { anchorItem: ag }
}
