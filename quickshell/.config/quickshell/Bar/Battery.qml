import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.Commons
import qs.Services
import qs.Panels

Pill {
    id: bat
    readonly property var dev: UPower.displayDevice
    visible: dev && dev.isLaptopBattery
    readonly property int pct: dev ? Math.round(dev.percentage * 100) : 0
    readonly property bool charging: dev && dev.state === UPowerDeviceState.Charging
    readonly property bool full: dev && dev.state === UPowerDeviceState.FullyCharged
    readonly property bool idleOnAc: dev && dev.state === UPowerDeviceState.PendingCharge
    readonly property bool plugged: charging || full || idleOnAc
    // 0–100% in Material's eight steps, and the charging set
    readonly property var icons: ["battery_0_bar", "battery_1_bar", "battery_2_bar", "battery_3_bar", "battery_4_bar", "battery_5_bar", "battery_6_bar", "battery_full"]
    readonly property var chargingIcons: ["battery_charging_20", "battery_charging_20", "battery_charging_30", "battery_charging_50", "battery_charging_60", "battery_charging_80", "battery_charging_90", "battery_charging_full"]
    // same rules as the waybar config: charging glyph, plug only when idle on AC, else the level
    readonly property int step: Math.min(7, Math.floor(pct / 12.5))
    readonly property string icon: charging ? chargingIcons[step] : idleOnAc ? "power" : icons[step]
    // hued themes: green while charging, yellow/red when low (the stock bar look);
    // mono themes tell the levels apart by shade alone
    readonly property color tone: Theme.hued
        ? (charging ? Theme.c.good : plugged ? Theme.c.accentBright
           : pct <= 15 ? Theme.c.critical : pct <= 30 ? Theme.c.warning : Theme.c.accentLight)
        : (plugged ? Theme.c.accentBright
           : pct <= 15 ? Theme.c.accentDim : pct <= 30 ? Theme.c.accentMid : Theme.c.accentLight)

    onClicked: Panels.toggle("power", bat)

    Icon {
        id: ic
        icon: bat.icon
        color: bat.tone
        SequentialAnimation on opacity {
            running: !bat.plugged && bat.pct <= 15
            loops: Animation.Infinite
            NumberAnimation { to: 0.3; duration: 500 }
            NumberAnimation { to: 1.0; duration: 500 }
            onRunningChanged: if (!running) ic.opacity = 1
        }
    }
    // Menu › Appearance › Bar › Battery percentage, in every skin (it was only drawn in
    // Legacy); fixed width so 9% → 10% doesn't push the bar
    FixedLabel { visible: !bat.vertical && Config.batteryPercent; text: bat.pct + "%"; widest: "100%"; color: bat.tone }

    PowerPanel { anchorItem: bat }
}
