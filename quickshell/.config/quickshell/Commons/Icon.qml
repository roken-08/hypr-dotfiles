import QtQuick
import qs.Commons

// An icon from Material Symbols Rounded, by name: Icon { icon: "wifi" }.
// The font draws names as glyphs (ligatures) and has variable axes, so an
// active state can be filled (fill: true) or heavier (weight). Anything that
// is not a plain name (a Nerd Font glyph from a user plugin or
// menu.local.jsonc) is drawn as text in the rice font, as before.
// Without the font installed, named icons stay blank instead of spelling
// their names (Theme.iconsOk; ttf-material-symbols-variable).
Text {
    property string icon
    property real size: Theme.fs(15)   // a full em wide; 15 matches the bar's text height
    property bool fill: false
    property int weight: 400
    readonly property bool material: /^[a-z0-9_]+$/.test(icon)

    text: material ? (Theme.iconsOk ? icon : "") : icon
    font.family: material ? Theme.iconFont : Theme.font
    font.pixelSize: size
    font.variableAxes: material ? { "FILL": fill ? 1 : 0, "wght": weight, "GRAD": 0, "opsz": Math.max(20, Math.min(48, size)) } : {}
    color: Theme.c.fg
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    renderType: Text.CurveRendering
    Behavior on color { ColorAnimation { duration: 150 } }
}
