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
    readonly property color tone: pct >= 90 ? Theme.c.accentDim : pct >= 70 ? Theme.c.accentMid : Theme.c.accentLight
    onClicked: Panels.toggle("agents", ag)
    onRightClicked: Agents.launch("")
    Icon { icon: "󱚝"; size: Theme.fontSize + 1; color: ag.tone }   // the rice's own robot glyph
    TextMetrics { id: widest; font.family: Theme.font; font.pixelSize: Theme.fontSize; font.weight: Font.Medium; text: "100%" }
    Label { visible: ag.pct >= 0 && !ag.vertical; text: ag.pct + "%"; width: widest.width; color: ag.tone }
    AgentsPanel { anchorItem: ag }
}
