import QtQuick
import QtQuick.Shapes
import qs.Commons
import "IconPaths.js" as Paths

// An icon by Material Symbols name: Icon { icon: "wifi"; color: … }.
// The shapes are Google's own SVGs (Rounded, filled, weight 600), fetched
// by Commons/icons/build.py into IconPaths.js and drawn here as vectors in
// the given colour, crisp at any size: the drawing made for 20px up to
// 28px, the 40px one above. A name that isn't there yet: add it to
// Commons/icons/names.txt and run build.py. Anything that isn't a plain
// name (a Nerd Font glyph from a user plugin or menu.local.jsonc, agent
// brand logos) is drawn as text in the rice font, as before.
Item {
    id: root
    property string icon
    property real size: Theme.fs(15)
    property color color: Theme.c.fg
    readonly property bool material: /^[a-z0-9_]+$/.test(icon)
    // [path data, viewBox x, y, size]
    readonly property var entry: material ? ((size > 28 ? Paths.large[icon] : Paths.small[icon]) || Paths.small[icon] || null) : null
    readonly property string path: entry ? entry[0] : ""
    readonly property real k: entry ? size / entry[3] : 1

    implicitWidth: material ? size : glyph.implicitWidth
    implicitHeight: material ? size : glyph.implicitHeight
    Behavior on color { ColorAnimation { duration: 150 } }

    Shape {
        visible: root.path !== ""
        // scale the icon's viewBox to size and move its corner to ours
        // (most are 0 -960 960 960, so that is a shift down by one size)
        x: (root.width - root.size) / 2 - (root.entry ? root.entry[1] * root.k : 0)
        y: (root.height - root.size) / 2 - (root.entry ? root.entry[2] * root.k : 0)
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: root.color
            strokeWidth: -1
            scale: Qt.size(root.k, root.k)
            PathSvg { path: root.path }
        }
    }

    Text {
        id: glyph
        visible: !root.material
        anchors.centerIn: parent
        text: root.material ? "" : root.icon
        font.family: Theme.font
        font.pixelSize: root.size
        color: root.color
        renderType: Text.CurveRendering
    }

    // tests the name itself: in onIconChanged the `material` binding can still
    // hold the previous icon's answer (a reused menu row), and warn for a glyph
    function check() {
        if (/^[a-z0-9_]+$/.test(icon) && !Paths.small[icon])
            console.warn("Icon: \"" + icon + "\" is not in Commons/icons/names.txt — add it and run Commons/icons/build.py")
    }
    Component.onCompleted: check()
    onIconChanged: check()
}
