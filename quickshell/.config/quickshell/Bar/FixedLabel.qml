import QtQuick
import qs.Commons

// Bar text that keeps the width of `widest` in a horizontal bar, so a number
// growing a digit (9% → 10%, 9K → 12K) never pushes the widgets beside it.
// In a side bar it takes its own width.
Label {
    id: fl
    property string widest: "88%"
    width: Config.vertical ? implicitWidth : m.width
    TextMetrics { id: m; font.family: Theme.font; font.pixelSize: Theme.fontSize; font.weight: Font.Medium; text: fl.widest }
}
