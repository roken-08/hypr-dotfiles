import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.Commons
import qs.Services

// The dock: pinned apps, then whatever else is running, on any screen edge.
// Click launches or focuses (again cycles the app's windows), middle-click
// opens a new window, right-click has Pin / New window / Close. Modes
// (Menu › Style › Dock, or `qs ipc call dock mode <m>`):
//   always       always shown, and windows keep clear of it
//   autohide     slides away; touch the screen edge to bring it back
//   intellihide  shown until a window would sit under it
// A fullscreen window hides it in every mode.
Variants {
    model: Dock.enabled ? Quickshell.screens : []

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        readonly property string pos: Dock.position
        readonly property bool vertical: Dock.vertical
        readonly property int pad: 6                     // card padding and gap between icons
        readonly property int tile: Dock.iconSize + 12   // icon plus its hover square
        readonly property int thick: tile + pad * 2      // the card across the edge
        readonly property int edgeGap: 6                 // card to screen edge (or to the bar)
        readonly property int depth: thick + edgeGap

        anchors {
            top:    pos === "top"    || vertical
            bottom: pos === "bottom" || vertical
            left:   pos === "left"   || !vertical
            right:  pos === "right"  || !vertical
        }
        // taller (wider) while the right-click menu is open: it lives in here
        readonly property real menuRoom: menu.open ? (vertical ? menu.width : menu.height) + menu.gap * 2 : 0
        implicitHeight: vertical ? 0 : depth + menuRoom
        implicitWidth: vertical ? depth + menuRoom : 0
        // always: windows keep clear of it. Otherwise 0, which still keeps it
        // beside a bar on the same edge instead of on top of it.
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: Dock.mode === "always" ? depth : 0
        color: "transparent"
        WlrLayershell.namespace: "hypr-dock"
        // Overlay, not Top: Hyprland reserves edges layer by layer from the bottom
        // up, so the bar (Top) always gets the edge first when both share one
        WlrLayershell.layer: WlrLayer.Overlay

        // ---- shown or hidden ------------------------------------------------
        readonly property var monitor: Hyprland.monitorFor(screen)
        readonly property var ws: monitor ? monitor.activeWorkspace : null
        // a real fullscreen window only: Hyprland's hasFullscreen is also true
        // for a maximized one (kitty maximized kept the dock away)
        readonly property bool fullscreen: !!(ws && ws.hasFullscreen
                                              && ws.toplevels.values.some(t => t.wayland && t.wayland.fullscreen))
        property bool hovered: false
        property bool overlapped: false
        readonly property bool menuOpen: menu.open
        readonly property bool shown: !fullscreen && (menuOpen || hovered || Dock.mode === "always"
                                                     || (Dock.mode === "intellihide" && !overlapped))
        // moved to another edge: vanish at once, then slide in from the new one
        property bool settling: false
        onPosChanged: { settling = true; settle2.restart() }
        Timer { id: settle2; interval: 160; onTriggered: win.settling = false }

        // 0 = in place, 1 = slid past the edge
        property real away: shown && !settling ? 0 : 1
        Behavior on away { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        // input: the card (or the edge strip while hidden); everything while the
        // right-click menu is open, or Hyprland drops the menu's clicks too
        Item { id: whole; anchors.fill: parent }
        mask: Region { item: win.menuOpen ? whole : win.away < 1 ? card : edge }

        // intellihide: does any window on this screen's workspace cover the card?
        function checkOverlap() {
            if (Dock.mode !== "intellihide" || !ws) { overlapped = false; return }
            const s = screen
            // where the card would be, in global layout coordinates
            const r = monitor && monitor.lastIpcObject && monitor.lastIpcObject.reserved
            const res = { left: r ? r[0] : 0, top: r ? r[1] : 0, right: r ? r[2] : 0, bottom: r ? r[3] : 0 }
            let x0, y0, x1, y1
            const along0 = (vertical ? s.height : s.width) / 2 - card.length / 2, along1 = along0 + card.length
            if (pos === "bottom") { y1 = s.height - res.bottom - edgeGap; y0 = y1 - thick; x0 = along0; x1 = along1 }
            else if (pos === "top") { y0 = res.top + edgeGap; y1 = y0 + thick; x0 = along0; x1 = along1 }
            else if (pos === "left") { x0 = res.left + edgeGap; x1 = x0 + thick; y0 = along0; y1 = along1 }
            else { x1 = s.width - res.right - edgeGap; x0 = x1 - thick; y0 = along0; y1 = along1 }
            x0 += s.x; x1 += s.x; y0 += s.y; y1 += s.y
            let hit = false
            for (const t of Hyprland.toplevels.values) {
                if (t.workspace !== ws) continue
                const o = t.lastIpcObject
                if (!o || !o.at || !o.size || o.hidden) continue
                // a few pixels don't count: a centred float that grazes the card
                // (hypr-float is 82% tall) shouldn't hide it
                const slack = 10
                if (o.at[0] < x1 - slack && o.at[0] + o.size[0] > x0 + slack && o.at[1] < y1 - slack && o.at[1] + o.size[1] > y0 + slack) { hit = true; break }
            }
            overlapped = hit
        }
        // window geometry changes arrive as events; drags and resizes don't,
        // so a slow poll covers those (intellihide only)
        Connections {
            target: Hyprland
            enabled: Dock.mode === "intellihide"
            function onRawEvent(e) {
                if (["openwindow", "closewindow", "movewindow", "movewindowv2", "changefloatingmode", "workspace", "workspacev2",
                     "fullscreen", "activewindowv2", "focusedmon"].indexOf(e.name) !== -1) refresh.restart()
            }
        }
        Timer { id: refresh; interval: 60; onTriggered: { Hyprland.refreshToplevels(); Hyprland.refreshMonitors(); settle.restart() } }
        Timer { id: settle; interval: 80; onTriggered: win.checkOverlap() }
        Timer { interval: 1000; repeat: true; running: Dock.mode === "intellihide"; triggeredOnStart: true; onTriggered: refresh.restart() }
        onWsChanged: refresh.restart()
        Connections { target: Dock; function onItemsChanged() { settle.restart() } }

        Timer { id: hideLater; interval: 600; onTriggered: win.hovered = false }
        Timer { id: showSoon; interval: 120; onTriggered: win.hovered = true }

        // a thin strip on the edge: touching it brings a hidden dock back
        Item {
            id: edge
            x: win.pos === "right" ? parent.width - width : 0
            y: win.pos === "bottom" ? parent.height - height : 0
            width: win.vertical ? 2 : parent.width
            height: win.vertical ? parent.height : 2
            HoverHandler {
                onHoveredChanged: {
                    if (hovered) { hideLater.stop(); showSoon.restart() }
                    else showSoon.stop()
                }
            }
        }

        // ---- the card -----------------------------------------------------
        Rectangle {
            id: card
            readonly property real length: (win.vertical ? icons.implicitHeight : icons.implicitWidth) + win.pad * 2
            readonly property real slide: win.away * (win.depth + 2)
            width: win.vertical ? win.thick : length
            height: win.vertical ? length : win.thick
            x: win.vertical ? (win.pos === "left" ? win.edgeGap - slide : parent.width - width - win.edgeGap + slide)
                            : (parent.width - width) / 2
            y: win.vertical ? (parent.height - height) / 2
                            : (win.pos === "top" ? win.edgeGap - slide : parent.height - height - win.edgeGap + slide)
            opacity: 1 - win.away * 0.6
            visible: win.away < 1 && !win.settling && Dock.items.length > 0
            radius: Theme.radius
            color: Dock.transparent ? "transparent" : Theme.alpha(Theme.c.bg0, 0.85)
            border.width: Dock.transparent ? 0 : 1
            border.color: Theme.c.border
            Behavior on color { ColorAnimation { duration: 150 } }

            HoverHandler {
                id: cardHover
                onHoveredChanged: {
                    if (hovered) { showSoon.stop(); hideLater.stop(); win.hovered = true }
                    else if (!win.menuOpen) hideLater.restart()
                }
            }

            // a Row or a Column, never a Grid being re-counted mid-switch
            // (same approach as the bar's sections)
            Item {
                id: icons
                x: win.pad; y: win.pad
                implicitWidth: win.vertical ? col.implicitWidth : row.implicitWidth
                implicitHeight: win.vertical ? col.implicitHeight : row.implicitHeight
                Row { id: row; spacing: win.pad; visible: !win.vertical; Repeater { model: win.vertical ? [] : Dock.items; delegate: appTile } }
                Column { id: col; spacing: win.pad; visible: win.vertical; Repeater { model: win.vertical ? Dock.items : []; delegate: appTile } }
            }
        }

        Component {
            id: appTile
            Item {
                id: app
                required property var modelData
                readonly property var entry: modelData.entry
                readonly property var windows: modelData.windows
                readonly property bool running: windows.length > 0
                readonly property bool focused: windows.some(t => t.activated)
                readonly property string name: entry ? entry.name : modelData.key
                width: win.tile; height: win.tile

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusSm
                    color: hit.containsMouse || (menu.open && menu.app === app) ? Theme.c.bg2
                         : app.focused ? Theme.alpha(Theme.c.bg2, 0.6) : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                }
                IconImage {
                    id: img
                    anchors.centerIn: parent
                    implicitSize: Dock.iconSize
                    source: app.entry && app.entry.icon ? Quickshell.iconPath(app.entry.icon, true)
                                                        : Quickshell.iconPath(app.modelData.key, true)
                    scale: hit.pressed ? 0.9 : 1
                    Behavior on scale { NumberAnimation { duration: 80 } }
                    Text {   // no icon anywhere: the name's first letter
                        visible: img.source === "" || img.status === Image.Error
                        anchors.centerIn: parent
                        text: app.name.charAt(0).toUpperCase()
                        font.family: Theme.font; font.pixelSize: Dock.iconSize * 0.55; font.weight: Font.DemiBold
                        color: Theme.c.fg
                    }
                }
                // running marker on the screen-edge side; wider for the focused app
                Rectangle {
                    visible: app.running
                    readonly property int len: app.focused ? 12 : 4
                    width: win.vertical ? 3 : len
                    height: win.vertical ? len : 3
                    radius: 1.5
                    color: app.focused ? Theme.c.accentBright : Theme.c.accentMid
                    // centred in the card padding between the icon and the edge
                    x: win.vertical ? (win.pos === "left" ? -(win.pad + 3) / 2 : parent.width + (win.pad - 3) / 2) : (parent.width - width) / 2
                    y: win.vertical ? (parent.height - height) / 2 : (win.pos === "top" ? -(win.pad + 3) / 2 : parent.height + (win.pad - 3) / 2)
                    Behavior on width { NumberAnimation { duration: 120 } }
                    Behavior on height { NumberAnimation { duration: 120 } }
                }
                MouseArea {
                    id: hit
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onContainsMouseChanged: {
                        if (containsMouse && !menu.open) { tip.app = app; tipDelay.restart() }
                        else if (tip.app === app) { tipDelay.stop(); tip.app = null }
                    }
                    onClicked: (e) => {
                        tipDelay.stop(); tip.app = null
                        if (e.button === Qt.RightButton) menu.show(app)
                        else if (e.button === Qt.MiddleButton) Dock.launch(app.modelData)
                        else Dock.activate(app.modelData)
                    }
                }
            }
        }

        // ---- name tooltip -------------------------------------------------
        Timer { id: tipDelay; interval: 450; onTriggered: tip.shownFor = tip.app }
        PopupWindow {
            id: tip
            property Item app: null
            property Item shownFor: null
            visible: shownFor !== null && shownFor === app && !menu.open && win.away === 0
            anchor.item: shownFor
            anchor.edges: win.pos === "bottom" ? Edges.Top : win.pos === "top" ? Edges.Bottom : win.pos === "left" ? Edges.Right : Edges.Left
            anchor.gravity: anchor.edges
            anchor.margins.top: win.pos === "top" ? win.pad + 8 : 0
            anchor.margins.bottom: win.pos === "bottom" ? win.pad + 8 : 0
            anchor.margins.left: win.pos === "left" ? win.pad + 8 : 0
            anchor.margins.right: win.pos === "right" ? win.pad + 8 : 0
            color: "transparent"
            implicitWidth: tipText.implicitWidth + 20
            implicitHeight: tipText.implicitHeight + 10
            onAppChanged: if (app === null) shownFor = null
            Rectangle {
                anchors.fill: parent
                radius: Theme.radius
                color: Theme.c.bg0
                border.width: 1; border.color: Theme.c.border
                Text {
                    id: tipText
                    anchors.centerIn: parent
                    text: tip.shownFor ? tip.shownFor.name + (tip.shownFor.windows.length > 1 ? "  ·  " + tip.shownFor.windows.length : "") : ""
                    font.family: Theme.font; font.pixelSize: Theme.fs(12)
                    color: Theme.c.fg
                }
            }
        }

        // ---- right-click menu ---------------------------------------------
        // Drawn inside the dock's own window, which grows to make room while
        // it is open: a separate popup surface above the dock got no input
        // from Hyprland at all (no hover, no clicks).
        MouseArea {   // a click on the dock's empty space closes it
            anchors.fill: parent
            visible: menu.open
            acceptedButtons: Qt.AllButtons
            onPressed: menu.open = false
        }
        HyprlandFocusGrab {   // …and so does a click anywhere else
            windows: [win]
            active: menu.open
            onCleared: menu.open = false
        }
        Rectangle {
            id: menu
            property bool open: false
            property Item app: null
            // where the app sits on the card, measured when the menu opens
            property real along: 0
            function show(a) {
                app = a
                const p = a.mapToItem(card, a.width / 2, a.height / 2)
                along = win.vertical ? p.y : p.x
                open = true
            }
            visible: open && app !== null
            width: 200
            height: rows.implicitHeight + 12
            readonly property real gap: 8
            x: win.vertical ? (win.pos === "left" ? card.x + card.width + gap : card.x - width - gap)
                            : Math.max(4, Math.min(win.width - width - 4, card.x + along - width / 2))
            y: !win.vertical ? (win.pos === "top" ? card.y + card.height + gap : card.y - height - gap)
                             : Math.max(4, Math.min(win.height - height - 4, card.y + along - height / 2))
            radius: Theme.radius
            color: Theme.c.bg0
            border.width: 1; border.color: Theme.c.border
            onOpenChanged: if (!open && !cardHover.hovered) hideLater.restart()

            readonly property var actions: {
                const a = app
                if (!a) return []
                const out = []
                const key = a.entry ? a.entry.id : a.modelData.key
                if (a.entry) out.push({ label: a.running ? "New window" : "Open", run: () => Dock.launch(a.modelData) })
                out.push({ label: Dock.isPinned(key) ? "Unpin from dock" : "Pin to dock", run: () => Dock.togglePin(key) })
                if (a.running) out.push({ label: a.windows.length > 1 ? "Close " + a.windows.length + " windows" : "Close", run: () => Dock.closeAll(a.modelData) })
                return out
            }

            Column {
                id: rows
                x: 6; y: 6
                width: parent.width - 12
                Text {
                    width: parent.width; height: 28
                    leftPadding: 8
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    text: menu.app ? menu.app.name : ""
                    font.family: Theme.font; font.pixelSize: Theme.fs(12); font.weight: Font.DemiBold
                    color: Theme.c.accentMid
                }
                Repeater {
                    model: menu.actions
                    delegate: Rectangle {
                        required property var modelData
                        width: rows.width; height: 30
                        radius: Theme.radiusSm
                        color: ma.containsMouse ? Theme.c.bg2 : "transparent"
                        Text {
                            x: 8; anchors.verticalCenter: parent.verticalCenter
                            text: parent.modelData.label
                            font.family: Theme.font; font.pixelSize: Theme.fs(12)
                            color: Theme.c.fg
                        }
                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { const run = parent.modelData.run; menu.open = false; run() }
                        }
                    }
                }
            }
        }
    }
}
