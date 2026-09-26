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
    readonly property string path: material ? ((size > 28 ? Paths.large[icon] : Paths.small[icon]) || Paths.small[icon] || "") : ""

    implicitWidth: material ? size : glyph.implicitWidth
    implicitHeight: material ? size : glyph.implicitHeight
    Behavior on color { ColorAnimation { duration: 150 } }

    Shape {
        visible: root.path !== ""
        // the symbols' viewBox is 0 -960 960 960: scale it down, then move
        // its top (y = -960) to our top
        x: (root.width - root.size) / 2
        y: (root.height - root.size) / 2 + root.size
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: root.color
            strokeWidth: -1
            scale: Qt.size(root.size / 960, root.size / 960)
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

    Component.onCompleted: if (material && !Paths.small[icon])
        console.warn("Icon: \"" + icon + "\" is not in Commons/icons/names.txt — add it and run Commons/icons/build.py")
    onIconChanged: if (material && !Paths.small[icon])
        console.warn("Icon: \"" + icon + "\" is not in Commons/icons/names.txt — add it and run Commons/icons/build.py")
}
