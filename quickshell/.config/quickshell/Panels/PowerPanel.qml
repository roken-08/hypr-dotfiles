import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.Commons
import qs.Bar
import qs.Services

// Power: the battery (level, state, time, charge rate, health), the screen's
// brightness, the power profile, and the session buttons.
Panel {
    id: p
    name: "power"
    panelWidth: 340

    readonly property var dev: UPower.displayDevice
    readonly property bool laptop: dev && dev.isLaptopBattery
    readonly property int pct: dev ? Math.round(dev.percentage * 100) : 0
    readonly property bool charging: dev && dev.state === UPowerDeviceState.Charging
    readonly property bool full: dev && dev.state === UPowerDeviceState.FullyCharged
    readonly property bool discharging: dev && dev.state === UPowerDeviceState.Discharging
    function fmt(sec) {
        if (!sec || sec <= 0) return ""
        const h = Math.floor(sec / 3600), m = Math.round((sec % 3600) / 60)
        return (h > 0 ? h + " h " : "") + m + " min"
    }
    readonly property string status: !dev ? "" :
        charging ? (fmt(dev.timeToFull) ? fmt(dev.timeToFull) + " to full" : "Charging") :
        discharging ? (fmt(dev.timeToEmpty) ? fmt(dev.timeToEmpty) + " left" : "On battery") :
        full ? "Fully charged" : "Plugged in"
    readonly property string rate: dev && Math.abs(dev.changeRate) >= 0.1 ? Math.abs(dev.changeRate).toFixed(1) + " W" : ""
    readonly property color levelColor: !Theme.hued ? Theme.c.accentBright
        : pct <= 15 && !charging ? Theme.c.critical : pct <= 30 && !charging ? Theme.c.warning : Theme.c.good

    // screen brightness: the first backlight that isn't NVIDIA's stub, as
    // scripts/brightness.sh picks it
    property string blDev: ""
    property real brightness: 0
    Process {
        id: findBl
        running: true
        command: ["sh", "-c", "brightnessctl -l -m -c backlight 2>/dev/null | cut -d, -f1 | grep -vi nvidia | head -n1"]
        stdout: StdioCollector { onStreamFinished: { p.blDev = text.trim(); if (p.blDev) readBl.running = true } }
    }
    Process {
        id: readBl
        command: ["brightnessctl", "-d", p.blDev, "-m"]
        stdout: StdioCollector { onStreamFinished: {
            const f = text.trim().split(",")          // name,class,current,percent,max
            if (f.length >= 5 && Number(f[4]) > 0) p.brightness = Number(f[2]) / Number(f[4])
        } }
    }
    onOpenChanged: if (open && blDev) readBl.running = true
    function setBrightness(v) {
        v = Math.max(0.05, Math.min(1, v))             // never 0: that turns the panel off
        brightness = v
        Quickshell.execDetached(["brightnessctl", "-q", "-d", blDev, "set", Math.round(v * 100) + "%"])
    }

    PanelHeader { title: "Power" }

    // battery ----------------------------------------------------------
    Item {
        visible: p.laptop
        width: parent.width; height: 64
        Rectangle {
            id: gauge
            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
            width: 34; height: 56; radius: Math.max(2, Theme.radius)
            color: "transparent"; border.width: 1.5; border.color: Theme.c.borderStrong
            Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: -4; width: 12; height: 4; radius: 1; color: Theme.c.borderStrong }
            Rectangle {
                x: 4; width: parent.width - 8
                height: Math.max(2, (parent.height - 8) * p.pct / 100)
                y: parent.height - 4 - height
                radius: Math.max(1, Theme.radius - 2)
                color: p.levelColor
                Behavior on height { NumberAnimation { duration: Motion.moveMs; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.moveCurve } }
            }
            Icon { anchors.centerIn: parent; visible: p.charging; icon: "bolt"; size: Theme.fs(18); color: Theme.c.bg0 }
        }
        Column {
            anchors.left: gauge.right; anchors.leftMargin: 16; anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Label { text: p.pct + "%"; font.pixelSize: Theme.fs(26); font.weight: Font.DemiBold; color: Theme.c.accentBright }
            Label { text: p.status; font.pixelSize: Theme.fs(12); color: Theme.c.fg }
        }
        Column {
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            Label { anchors.right: parent.right; visible: p.rate !== ""; text: (p.charging ? "+" : "−") + p.rate
                    font.pixelSize: Theme.fs(11); color: Theme.c.accentMid }
            Label { anchors.right: parent.right; visible: p.dev && p.dev.healthSupported
                    text: "Health " + (p.dev ? Math.round(p.dev.healthPercentage) : 0) + "%"; font.pixelSize: Theme.fs(11); color: Theme.c.accentMid }
        }
    }

    // brightness -------------------------------------------------------
    PanelSection { visible: p.blDev !== ""; text: "Brightness"; detail: Math.round(p.brightness * 100) + "%" }
    Item {
        visible: p.blDev !== ""
        width: parent.width; height: 32
        Icon { id: bIcon; x: 6; anchors.verticalCenter: parent.verticalCenter; icon: "brightness_medium"; size: Theme.fs(16); color: Theme.c.accentLight }
        Slider {
            anchors.left: bIcon.right; anchors.leftMargin: 14; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            width: undefined
            value: p.brightness
            onMoved: (v) => p.setBrightness(v)
        }
    }

    // power profile ----------------------------------------------------
    PanelSection { text: "Profile" }
    Segmented {
        current: PowerProfiles.profile
        options: [
            { label: "Saver",       icon: "eco",     value: PowerProfile.PowerSaver },
            { label: "Balanced",    icon: "balance", value: PowerProfile.Balanced },
            { label: "Performance", icon: "bolt",    value: PowerProfile.Performance, ok: PowerProfiles.hasPerformanceProfile }
        ]
        onPicked: (v) => PowerProfiles.profile = v
    }

    PanelDivider {}

    // session ----------------------------------------------------------
    Row {
        id: session
        width: parent.width; spacing: 8
        Repeater {
            model: [
                { label: "Lock",    icon: "lock",               act: "lock" },
                { label: "Sleep",   icon: "bedtime",            act: "suspend" },
                { label: "Restart", icon: "restart_alt",        act: "reboot" },
                { label: "Off",     icon: "power_settings_new", act: "poweroff" }
            ]
            Rectangle {
                id: tile
                required property var modelData
                width: (session.width - 3 * session.spacing) / 4; height: 58
                radius: Theme.radius
                readonly property bool risky: modelData.act === "reboot" || modelData.act === "poweroff"
                color: tm.containsMouse ? Theme.c.bg2 : Theme.c.bg1
                border.width: 1; border.color: tm.containsMouse ? Theme.c.borderStrong : Theme.c.border
                Behavior on color { ColorAnimation { duration: Motion.fadeMs } }
                Column {
                    anchors.centerIn: parent; spacing: 5
                    Icon { anchors.horizontalCenter: parent.horizontalCenter; icon: tile.modelData.icon; size: Theme.fs(19)
                           color: tile.risky && tm.containsMouse && Theme.hued ? Theme.c.critical : Theme.c.accentLight }
                    Label { anchors.horizontalCenter: parent.horizontalCenter; text: tile.modelData.label; font.pixelSize: Theme.fs(11); color: Theme.c.fg }
                }
                MouseArea {
                    id: tm
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Panels.close()
                        if (tile.modelData.act === "lock") Lock.lock()        // the shell's lock, as SUPER+L
                        else Quickshell.execDetached(["systemctl", tile.modelData.act])
                    }
                }
            }
        }
    }
}
