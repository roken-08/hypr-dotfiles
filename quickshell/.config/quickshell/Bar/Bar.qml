import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons

// One bar per screen, on any edge. Three skins (Theme.barStyle):
//   pill      "Legacy": floating bordered modules — the classic waybar look
//   floating  the minimal strip, inset from the edge with rounded corners
//   minimal   flat strip flush with the edge, Omarchy layout
// floating and minimal share one layout and can be transparent.
// Sections and their widgets come from shell.json (Config.layoutFor).
//
// Gestures on empty bar space, like Omarchy: drag (or press-and-hold) to
// move the bar to another screen edge — the screen is split along its
// diagonals and the triangle under the cursor is the target, previewed
// while you drag; double-click toggles transparency (not on Legacy).
Scope {
    id: bars

    property bool moving: false
    property string candidate: ""
    function nearestEdge(nx, ny) {
        let edge = "top", best = ny
        if (1 - ny < best) { edge = "bottom"; best = 1 - ny }
        if (nx < best)     { edge = "left";   best = nx }
        if (1 - nx < best) { edge = "right";  best = 1 - nx }
        return edge
    }
    function finish() {
        const edge = candidate
        moving = false; candidate = ""
        if (edge !== "" && edge !== Config.position) Config.setPosition(edge)
    }

    IpcHandler {
        target: "bar"
        // pill | legacy | floating | minimal | auto (follow the theme)
        function style(name: string): string {
            if (name === "legacy") name = "pill"
            if (Config.skins.indexOf(name) !== -1) Config.set("bar.skin", name)
            else if (name === "auto" || name === "") Config.set("bar.skin", "")
            return Theme.barStyle
        }
        function current(): string { return Theme.barStyle }
        // cycles Legacy -> floating -> minimal
        function toggle(): string {
            const k = Config.skins
            Config.set("bar.skin", k[(k.indexOf(Theme.barStyle) + 1) % k.length])
            return Theme.barStyle
        }
        function position(edge: string): string { Config.setPosition(edge); return Config.position }
        function transparent(): bool { Config.toggleTransparent(); return Config.transparent }
        function visible(): bool { Config.set("bar.hidden", !Config.hidden); return !Config.hidden }
        // the current skin's widgets back to the shipped order
        function reset(): void { Config.resetLayout(Theme.barLayout) }
        function battery(): bool { Config.set("bar.battery", !Config.batteryPercent); return Config.batteryPercent }
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: perScreen
            required property var modelData

            PanelWindow {
                id: win
                screen: perScreen.modelData
                visible: !Config.hidden && Config.ready && Theme.ready

                readonly property bool pill: Theme.barStyle === "pill"
                readonly property bool floating: Theme.barStyle === "floating"
                readonly property string pos: Config.position
                readonly property bool vertical: Config.vertical
                readonly property bool transparent: !pill && Config.transparent
                readonly property int thickness: pill ? (vertical ? 44 : 37) : (vertical ? 28 : 26)
                readonly property int edgeGap: pill || floating ? 5 : 0
                readonly property int sideGap: pill || floating ? 6 : 0

                anchors {
                    top:    pos === "top"    || vertical
                    bottom: pos === "bottom" || vertical
                    left:   pos === "left"   || !vertical
                    right:  pos === "right"  || !vertical
                }
                margins {
                    top:    pos === "top"    ? edgeGap : (vertical ? sideGap : 0)
                    bottom: pos === "bottom" ? edgeGap : (vertical ? sideGap : 0)
                    left:   pos === "left"   ? edgeGap : (vertical ? 0 : sideGap)
                    right:  pos === "right"  ? edgeGap : (vertical ? 0 : sideGap)
                }
                // Dragging the bar over an empty workspace: Hyprland keeps a
                // pressed button's pointer focus on the pressed surface only
                // while *some* surface has keyboard focus (InputManager.cpp).
                // With a window that is the window; with none, the bar lost the
                // drag as soon as it left it. So on an empty workspace the bar
                // takes keyboard focus on click (nothing to steal it from); with
                // windows it never does. No resizing: resizing the surface
                // flashed its old buffer stretched over the screen.
                readonly property var ws: Hyprland.monitorFor(screen) ? Hyprland.monitorFor(screen).activeWorkspace : null
                readonly property bool emptyWorkspace: !ws || ws.toplevels.values.length === 0
                WlrLayershell.keyboardFocus: emptyWorkspace ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
                implicitHeight: vertical ? 0 : thickness
                implicitWidth: vertical ? thickness : 0
                exclusionMode: ExclusionMode.Normal
                exclusiveZone: thickness
                color: "transparent"
                WlrLayershell.namespace: "hypr-bar"

                // the visible bar, pinned to the anchored edge of the surface
                Item {
                    id: strip
                    width: win.vertical ? win.thickness : parent.width
                    height: win.vertical ? parent.height : win.thickness
                    x: win.pos === "right" ? parent.width - width : 0
                    y: win.pos === "bottom" ? parent.height - height : 0

                    // minimal: flat strip; floating: inset, rounded, bordered;
                    // Legacy draws its own pills
                    Rectangle {
                        anchors.fill: parent
                        visible: !win.pill
                        radius: win.floating ? Theme.radius : 0
                        color: win.transparent ? "transparent" : Theme.c.bg0
                        border.width: win.floating && !win.transparent ? 1 : 0
                        border.color: Theme.c.border
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    // ---- gestures on empty space (under the widgets) ----
                    MouseArea {
                        id: gesture
                        anchors.fill: parent
                        z: 0
                        acceptedButtons: Qt.LeftButton
                        pressAndHoldInterval: 400   // a slow click is not a move
                        cursorShape: bars.moving ? Qt.ClosedHandCursor : Qt.ArrowCursor
                        property real px: 0
                        property real py: 0
                        property bool suppress: false
                        function begin(x, y) {
                            if (bars.moving) return
                            bars.moving = true
                            update(x, y)
                        }
                        function update(x, y) {
                            // strip position within the screen, then normalise
                            const sx = (win.pos === "right" ? win.screen.width - win.thickness - win.margins.right : win.margins.left) + x
                            const sy = (win.pos === "bottom" ? win.screen.height - win.thickness - win.margins.bottom : win.margins.top) + y
                            bars.candidate = bars.nearestEdge(Math.max(0, Math.min(1, sx / win.screen.width)),
                                                              Math.max(0, Math.min(1, sy / win.screen.height)))
                        }
                        onPressed: (e) => { px = e.x; py = e.y; suppress = false }
                        onPressAndHold: (e) => { if (pressed) begin(e.x, e.y) }
                        onPositionChanged: (e) => {
                            if (!(e.buttons & Qt.LeftButton)) return
                            if (!bars.moving) { if (Math.abs(e.x - px) + Math.abs(e.y - py) < 4) return; begin(e.x, e.y) }
                            else update(e.x, e.y)
                        }
                        onReleased: {
                            if (!bars.moving) return
                            suppress = true
                            bars.finish()
                        }
                        onCanceled: { bars.moving = false; bars.candidate = "" }
                        onDoubleClicked: (e) => {
                            if (suppress) { suppress = false; return }
                            if (!win.pill) Config.toggleTransparent()
                        }
                    }

                    // ---- sections ----
                    component Section: Item {
                        id: sec
                        property string name
                        // spacers only between widgets: turning widgets off left two side by
                        // side (a double gap) or one at the section's edge
                        readonly property var entries: {
                            const out = []
                            for (const id of Config.layoutFor(Theme.barLayout, name)) {
                                if (id === "spacer" && (out.length === 0 || out[out.length - 1] === "spacer")) continue
                                out.push(id)
                            }
                            while (out.length && out[out.length - 1] === "spacer") out.pop()
                            return out
                        }
                        implicitWidth: win.vertical ? col.implicitWidth : row.implicitWidth
                        implicitHeight: win.vertical ? col.implicitHeight : row.implicitHeight
                        width: implicitWidth
                        height: implicitHeight
                        Row {
                            id: row
                            visible: !win.vertical
                            spacing: win.pill ? 8 : 2
                            Repeater {
                                model: win.vertical ? [] : sec.entries
                                WidgetLoader { required property var modelData; widgetId: modelData; anchors.verticalCenter: parent.verticalCenter }
                            }
                        }
                        Column {
                            id: col
                            visible: win.vertical
                            spacing: win.pill ? 8 : 6
                            Repeater {
                                model: win.vertical ? sec.entries : []
                                WidgetLoader { required property var modelData; widgetId: modelData; anchors.horizontalCenter: parent.horizontalCenter }
                            }
                        }
                    }

                    // positioned by hand: flipping anchors at runtime leaves items
                    // stretched or pinned (anchors override the size bindings)
                    Section {
                        id: leftSec
                        name: "left"
                        x: win.vertical ? (parent.width - width) / 2 : 8
                        y: win.vertical ? 8 : (parent.height - height) / 2
                    }
                    Section {
                        id: centerSec
                        name: "center"
                        // centred, but never under the right (or left) section when
                        // those grow: it gives way, sliding toward the free side
                        x: win.vertical ? (parent.width - width) / 2
                                        : Math.max(leftSec.x + leftSec.width + 12,
                                                   Math.min((parent.width - width) / 2, rightSec.x - width - 12))
                        y: !win.vertical ? (parent.height - height) / 2
                                         : Math.max(leftSec.y + leftSec.height + 12,
                                                    Math.min((parent.height - height) / 2, rightSec.y - height - 12))
                    }
                    Section {
                        id: rightSec
                        name: "right"
                        x: win.vertical ? (parent.width - width) / 2 : parent.width - width - (win.pill ? 2 : 8)
                        y: win.vertical ? parent.height - height - (win.pill ? 2 : 8) : (parent.height - height) / 2
                    }
                }
            }

            // edge preview while moving: a translucent strip on the candidate
            // edge. One fixed window per edge, only shown, never re-anchored:
            // a single window moving between edges passed through a full-screen
            // size for a frame and flashed over everything.
            Repeater {
                model: ["top", "bottom", "left", "right"]
                PanelWindow {
                    id: ghost
                    required property string modelData
                    readonly property bool v: modelData === "left" || modelData === "right"
                    screen: perScreen.modelData
                    visible: bars.moving && bars.candidate === modelData && modelData !== Config.position
                    anchors {
                        top:    modelData === "top"    || v
                        bottom: modelData === "bottom" || v
                        left:   modelData === "left"   || !v
                        right:  modelData === "right"  || !v
                    }
                    implicitHeight: v ? 0 : win.thickness
                    implicitWidth: v ? win.thickness : 0
                    color: "transparent"
                    exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.layer: WlrLayer.Overlay
                    WlrLayershell.namespace: "hypr-bar-ghost"
                    mask: Region {}
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: Theme.radius
                        color: Theme.alpha(Theme.c.fg, 0.18)
                        border.width: 1
                        border.color: Theme.c.borderStrong
                    }
                }
            }
        }
    }
}
