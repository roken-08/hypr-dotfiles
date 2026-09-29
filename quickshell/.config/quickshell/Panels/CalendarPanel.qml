import QtQuick
import qs.Commons
import qs.Bar

// Under the clock: today in words, then the month. Arrows or the wheel step
// months; "Today" comes back. Leading and trailing days of the next and
// previous months fill the grid, dimmed, so it never has empty rows.
Panel {
    id: p
    name: "calendar"
    panelWidth: 312
    property date shown: new Date()
    property date today: new Date()
    function step(n) { shown = new Date(shown.getFullYear(), shown.getMonth() + n, 1) }
    readonly property bool onToday: shown.getFullYear() === today.getFullYear() && shown.getMonth() === today.getMonth()
    onOpenChanged: if (open) { today = new Date(); shown = new Date() }

    // today, in words
    Column {
        width: parent.width; spacing: 2
        Label { text: Qt.formatDate(p.today, "dddd"); font.pixelSize: Theme.fs(12); color: Theme.c.accentMid }
        Label { text: Qt.formatDate(p.today, "d MMMM yyyy"); font.pixelSize: Theme.fs(17); font.weight: Font.DemiBold; color: Theme.c.accentBright }
    }
    PanelDivider {}

    // month and its arrows
    Item {
        width: parent.width; height: 28
        Label { anchors.left: parent.left; anchors.leftMargin: 2; anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDate(p.shown, "MMMM yyyy"); font.pixelSize: Theme.fs(13); font.weight: Font.DemiBold; color: Theme.c.fg }
        Row {
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            PanelButton { visible: !p.onToday; text: "Today"; implicitHeight: 26; onClicked: p.shown = new Date() }
            IconButton { icon: "chevron_left"; onClicked: p.step(-1) }
            IconButton { icon: "chevron_right"; onClicked: p.step(1) }
        }
        MouseArea { anchors.fill: parent; z: -1; onWheel: (w) => p.step(w.angleDelta.y > 0 ? -1 : 1) }
    }

    Column {
        width: parent.width; spacing: 2
        readonly property real cell: width / 7
        Row {
            Repeater {
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                Label { required property string modelData; required property int index
                        width: parent.parent.cell; horizontalAlignment: Text.AlignHCenter
                        text: modelData; font.pixelSize: Theme.fs(10.5); font.weight: Font.DemiBold
                        color: index >= 5 ? Theme.c.accentDim : Theme.c.accentMid }
            }
        }
        Grid {
            id: days
            columns: 7
            readonly property int first: (new Date(p.shown.getFullYear(), p.shown.getMonth(), 1).getDay() + 6) % 7   // Monday first
            readonly property int count: new Date(p.shown.getFullYear(), p.shown.getMonth() + 1, 0).getDate()
            readonly property int prevCount: new Date(p.shown.getFullYear(), p.shown.getMonth(), 0).getDate()
            // as many weeks as the month needs
            readonly property int weeks: Math.ceil((first + count) / 7)
            Repeater {
                model: days.weeks * 7
                Item {
                    required property int index
                    readonly property int day: index - days.first + 1
                    readonly property bool inMonth: day >= 1 && day <= days.count
                    readonly property int shownDay: day < 1 ? days.prevCount + day : day > days.count ? day - days.count : day
                    readonly property bool weekend: index % 7 >= 5
                    readonly property bool isToday: inMonth && p.onToday && p.today.getDate() === day
                    width: parent.parent.cell; height: 32
                    Rectangle {
                        anchors.centerIn: parent; width: 30; height: 30
                        radius: Theme.radius
                        color: parent.isToday ? Theme.c.accentBright : dm.containsMouse && parent.inMonth ? Theme.c.bg2 : "transparent"
                        Behavior on color { ColorAnimation { duration: Motion.fadeMs } }
                    }
                    Label { anchors.centerIn: parent; text: parent.shownDay; font.pixelSize: Theme.fs(12)
                            font.weight: parent.isToday ? Font.DemiBold : Font.Normal
                            color: parent.isToday ? Theme.c.bg0 : !parent.inMonth ? Theme.c.bg4 : parent.weekend ? Theme.c.accentMid : Theme.c.fg }
                    MouseArea { id: dm; anchors.fill: parent; hoverEnabled: true }
                }
            }
        }
    }
}
