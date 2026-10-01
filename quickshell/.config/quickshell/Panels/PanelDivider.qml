import QtQuick
import qs.Commons

// A hairline between a panel's sections.
Item {
    width: parent.width
    height: 9
    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 1; color: Theme.c.border }
}
