import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.Commons
import qs.Services

// A panel is a drawer that slides out of the bar, under the widget that
// opened it, and slides back in when it closes (Motion.in / Motion.out).
//   Legacy (pill) bar: the pill is the drawer's tab; pill and panel are one
//     outlined shape.
//   Floating / minimal bar: the panel hangs from the bar's edge on two small
//     curved shoulders, with a short accent line under its widget.
//   Transparent bar: nothing to hang from, so it floats a little below.
// Works on any bar edge. Children go in `content`; `backdrop` is drawn
// under them, clipped to the panel (the media panel's blurred cover).
PopupWindow {
    id: popup
    required property string name
    required property Item anchorItem
    default property alias content: column.data
    property alias backdrop: backdropItem.data
    property int panelWidth: 320
    property int pad: 16
    property alias spacing: column.spacing

    readonly property bool open: anchorItem !== null && name !== "" && Panels.open === name && Panels.item === anchorItem
    // 0 = closed, 1 = open; the popup stays mapped until the close has played
    property real progress: 0
    property bool shown: false
    visible: shown || progress > 0
    color: "transparent"

    // ---- how the panel meets the bar ----
    readonly property bool vertical: Config.vertical
    readonly property bool flip: Config.position === "bottom" || Config.position === "right"
    readonly property bool tab: Theme.barStyle === "pill"
    readonly property bool detached: !tab && Config.transparent
    readonly property int r: Theme.radius
    readonly property int f: detached ? 0 : (r > 0 ? Math.max(4, r + 2) : 0)   // shoulder radius
    readonly property color fill: Theme.c.bg0
    readonly property color line: tab ? Theme.c.bg3 : Theme.c.border

    // the body: L along the bar, D away from it
    readonly property real contentH: column.implicitHeight + pad * 2
    readonly property real bodyL: vertical ? contentH : panelWidth
    readonly property real bodyD: vertical ? panelWidth : contentH

    // layout in "bar frame" coordinates: a runs along the bar, u away from it,
    // both from the popup's own corner nearest the bar (set by place())
    property real n0: 0           // u where the body starts (the tab's neck, or 1px over the bar's border)
    property real bx0: 0          // a where the body starts
    property real t0: 0           // the widget's extent along the bar
    property real t1: 0
    property real popL: bodyL     // popup length along the bar
    property bool mergeLo: false  // the tab sits at the body's end: one straight edge, no shoulder
    property bool mergeHi: false
    readonly property real bx1: bx0 + bodyL
    readonly property real popD: n0 + bodyD

    implicitWidth: Math.max(1, vertical ? popD : popL)
    implicitHeight: Math.max(1, vertical ? popL : popD)

    anchor.item: anchorItem
    anchor.adjustment: PopupAdjustment.None
    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: (Config.position === "bottom" ? Edges.Top : Edges.Bottom)
                  | (Config.position === "right" ? Edges.Left : Edges.Right)

    function place() {
        if (!anchorItem) return
        const w = anchorItem.QsWindow.window
        if (!w) return
        const p = anchorItem.mapToItem(null, 0, 0)
        const iA = vertical ? p.y : p.x
        const iL = vertical ? anchorItem.height : anchorItem.width
        const thick = vertical ? w.width : w.height
        const winLen = vertical ? w.height : w.width
        const scr = w.screen ? (vertical ? w.screen.height : w.screen.width) : winLen
        // the bar's far edge, and the widget's far side, across the bar
        const edge = flip ? 0 : thick
        const itemFar = flip ? (vertical ? p.x : p.y) : (vertical ? p.x + anchorItem.width : p.y + anchorItem.height)
        const sign = flip ? -1 : 1
        let start                                   // where the popup starts, across the bar
        // tab: start 1px inside the pill, over its border on that side, so the
        // pill and the neck are one outline
        if (tab) { start = Math.round(itemFar) - 2 * sign; n0 = Math.max(0, Math.abs(edge - start)) }
        else if (detached) { start = edge + sign * 8; n0 = 0 }
        else { start = edge - sign; n0 = 1 }        // 1px back over the bar's border, to hide it
        // along the bar: centred on the widget, kept on the screen (tab) or
        // on the bar with room for the shoulders (floating / minimal)
        const off = (scr - winLen) / 2              // the bar window's inset on the screen
        const lo = tab || detached ? 8 - off : f + r
        const hi = tab || detached ? scr - 8 - off - bodyL : winLen - f - r - bodyL
        let a = Math.max(lo, Math.min(hi, iA + iL / 2 - bodyL / 2))
        mergeLo = false; mergeHi = false
        if (tab) {                                  // the neck must fit between the body's corners
            if (iA - f - r < a) { a = iA; mergeLo = true }
            else if (iA + iL + f + r > a + bodyL) { a = iA + iL - bodyL; mergeHi = true }
        }
        const popA = tab || detached ? a : a - f
        bx0 = a - popA
        popL = bodyL + (tab || detached ? 0 : 2 * f)
        t0 = iA - popA; t1 = iA + iL - popA
        // the anchor point, relative to the widget
        const along = popA - iA, across = start - (vertical ? p.x : p.y)
        anchor.rect.x = vertical ? across : along
        anchor.rect.y = vertical ? along : across
        anchor.rect.width = 0; anchor.rect.height = 0
    }

    // ---- open / close ----
    NumberAnimation {
        id: anim
        target: popup; property: "progress"
        easing.type: Easing.BezierSpline
        onFinished: if (popup.progress === 0 && Panels.closing === popup.anchorItem) Panels.closing = null
    }
    onOpenChanged: {
        anim.stop()
        if (open) {
            place(); shown = true
            anim.to = 1; anim.duration = Motion.inMs; anim.easing.bezierCurve = Motion.inCurve
        } else {
            shown = false; Panels.closing = anchorItem
            anim.to = 0; anim.duration = Motion.outMs; anim.easing.bezierCurve = Motion.outCurve
        }
        anim.start()
    }
    onBodyLChanged: if (open && vertical) place()
    onPanelWidthChanged: if (open) place()
    Component.onCompleted: Panels.register(name, anchorItem)

    HyprlandFocusGrab {
        windows: popup.anchorItem ? [popup, popup.anchorItem.QsWindow.window] : [popup]
        active: popup.open
        onCleared: if (popup.open) Panels.close()
    }

    // ---- drawing ----
    // bar frame (a, u) → popup pixels
    function px(a, u) { return vertical ? (flip ? popD - u : u) : a }
    function py(a, u) { return vertical ? a : (flip ? popD - u : u) }
    function pt(a, u) { return px(a, u).toFixed(2) + " " + py(a, u).toFixed(2) }
    // a quarter circle from (a1,u1) to (a2,u2) around the corner (ac,uc)
    function arc(a1, u1, ac, uc, a2, u2) {
        const k = 0.5523
        return " C " + pt(a1 + (ac - a1) * k, u1 + (uc - u1) * k) + " " + pt(a2 + (ac - a2) * k, u2 + (uc - u2) * k) + " " + pt(a2, u2)
    }
    // the outline; `closed` adds the run along the bar that is filled but not stroked
    function outline(closed) {
        const D = bodyD, e = n0 + D, R = r
        let s = ""
        if (tab) {
            const fn = Math.min(f, n0)              // the neck may be shorter than a shoulder
            // down the low side
            if (mergeLo) s = "M " + pt(bx0 + 0.5, 0)
            else s = "M " + pt(t0 + 0.5, 0) + " L " + pt(t0 + 0.5, n0 - fn) + arc(t0 + 0.5, n0 - fn, t0 + 0.5, n0 + 0.5, t0 + 0.5 - fn, n0 + 0.5)
                     + " L " + pt(bx0 + 0.5 + R, n0 + 0.5) + arc(bx0 + 0.5 + R, n0 + 0.5, bx0 + 0.5, n0 + 0.5, bx0 + 0.5, n0 + 0.5 + R)
            s += " L " + pt(bx0 + 0.5, e - 0.5 - R) + arc(bx0 + 0.5, e - 0.5 - R, bx0 + 0.5, e - 0.5, bx0 + 0.5 + R, e - 0.5)
            s += " L " + pt(bx1 - 0.5 - R, e - 0.5) + arc(bx1 - 0.5 - R, e - 0.5, bx1 - 0.5, e - 0.5, bx1 - 0.5, e - 0.5 - R)
            if (mergeHi) s += " L " + pt(bx1 - 0.5, 0)
            else s += " L " + pt(bx1 - 0.5, n0 + 0.5 + R) + arc(bx1 - 0.5, n0 + 0.5 + R, bx1 - 0.5, n0 + 0.5, bx1 - 0.5 - R, n0 + 0.5)
                      + " L " + pt(t1 - 0.5 + fn, n0 + 0.5) + arc(t1 - 0.5 + fn, n0 + 0.5, t1 - 0.5, n0 + 0.5, t1 - 0.5, n0 - fn) + " L " + pt(t1 - 0.5, 0)
        } else if (detached) {
            s = "M " + pt(bx0 + 0.5 + R, 0.5) + " L " + pt(bx1 - 0.5 - R, 0.5) + arc(bx1 - 0.5 - R, 0.5, bx1 - 0.5, 0.5, bx1 - 0.5, 0.5 + R)
              + " L " + pt(bx1 - 0.5, e - 0.5 - R) + arc(bx1 - 0.5, e - 0.5 - R, bx1 - 0.5, e - 0.5, bx1 - 0.5 - R, e - 0.5)
              + " L " + pt(bx0 + 0.5 + R, e - 0.5) + arc(bx0 + 0.5 + R, e - 0.5, bx0 + 0.5, e - 0.5, bx0 + 0.5, e - 0.5 - R)
              + " L " + pt(bx0 + 0.5, 0.5 + R) + arc(bx0 + 0.5, 0.5 + R, bx0 + 0.5, 0.5, bx0 + 0.5 + R, 0.5)
            return s + " Z"
        } else {
            // shoulders flare out of the bar's edge on both sides of the body
            const u = n0 - 0.5                     // the bar's border line
            s = "M " + pt(bx0 - f, u) + arc(bx0 - f, u, bx0 + 0.5, u, bx0 + 0.5, u + f)
              + " L " + pt(bx0 + 0.5, e - 0.5 - R) + arc(bx0 + 0.5, e - 0.5 - R, bx0 + 0.5, e - 0.5, bx0 + 0.5 + R, e - 0.5)
              + " L " + pt(bx1 - 0.5 - R, e - 0.5) + arc(bx1 - 0.5 - R, e - 0.5, bx1 - 0.5, e - 0.5, bx1 - 0.5, e - 0.5 - R)
              + " L " + pt(bx1 - 0.5, u + f) + arc(bx1 - 0.5, u + f, bx1 - 0.5, u, bx1 + f, u)
            if (closed) s += " L " + pt(bx1 + f, 0) + " L " + pt(bx0 - f, 0)
        }
        return closed ? s + " Z" : s
    }

    // the drawer, clipped at the bar so it slides out from under it
    Item {
        id: clipper
        anchors.fill: parent
        clip: true

        Item {
            id: stage
            width: parent.width; height: parent.height
            // slides in from under the bar: back by the body's depth when closed
            readonly property real back: (1 - popup.progress) * (popup.bodyD + popup.f + 2)
            x: popup.vertical ? (popup.flip ? back : -back) : 0
            y: popup.vertical ? 0 : (popup.flip ? back : -back)

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeWidth: -1
                    fillColor: popup.fill
                    PathSvg { path: popup.outline(true) }
                }
                ShapePath {
                    strokeWidth: 1
                    strokeColor: popup.line
                    fillColor: "transparent"
                    capStyle: ShapePath.FlatCap
                    joinStyle: ShapePath.RoundJoin
                    PathSvg { path: popup.outline(false) }
                }
            }

            // the body's own rectangle: backdrop and content live here
            Item {
                id: body
                x: popup.vertical ? (popup.flip ? popup.popD - popup.n0 - popup.bodyD : popup.n0) : popup.bx0
                y: popup.vertical ? popup.bx0 : (popup.flip ? popup.popD - popup.n0 - popup.bodyD : popup.n0)
                width: popup.vertical ? popup.bodyD : popup.bodyL
                height: popup.vertical ? popup.bodyL : popup.bodyD

                ClippingRectangle {
                    id: backdropItem
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: Math.max(0, popup.r - 1)
                    color: "transparent"
                    visible: children.length > 0
                }

                // which widget this panel belongs to (floating / minimal bar)
                Rectangle {
                    visible: !popup.tab && !popup.detached
                    readonly property real lo: Math.max(0, popup.t0 - popup.bx0 + 3)
                    readonly property real hi: Math.min(popup.bodyL, popup.t1 - popup.bx0 - 3)
                    x: popup.vertical ? (popup.flip ? parent.width - 2 : 0) : lo
                    y: popup.vertical ? lo : (popup.flip ? parent.height - 2 : 0)
                    width: popup.vertical ? 2 : Math.max(0, hi - lo)
                    height: popup.vertical ? Math.max(0, hi - lo) : 2
                    radius: 1
                    color: Theme.c.accentBright
                    opacity: popup.progress
                }

                Item {
                    anchors.fill: parent
                    opacity: Math.min(1, Math.max(0, (popup.progress - 0.15) / 0.6))
                    Column {
                        id: column
                        x: popup.pad; y: popup.pad
                        width: parent.width - popup.pad * 2
                        spacing: 10
                    }
                }
                focus: popup.open
                Keys.onEscapePressed: Panels.close()
            }
        }
    }
}
