import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.Commons
import qs.Bar
import qs.Services

Panel {
    id: p
    name: "bluetooth"

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool on: adapter && adapter.enabled
    readonly property var devices: {
        const all = Bluetooth.devices.values.filter(d => d.name || d.deviceName)
        all.sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || (a.name || "").localeCompare(b.name || ""))
        return all
    }
    onOpenChanged: if (adapter) adapter.discovering = open && on

    function icon(d) {
        const i = String(d.icon || "")
        if (i.indexOf("headset") >= 0 || i.indexOf("headphone") >= 0) return "headphones"
        if (i.indexOf("audio") >= 0) return "speaker"
        if (i.indexOf("phone") >= 0) return "smartphone"
        if (i.indexOf("mouse") >= 0) return "mouse"
        if (i.indexOf("keyboard") >= 0) return "keyboard"
        if (i.indexOf("computer") >= 0) return "computer"
        return "bluetooth"
    }
    function state(d) {
        if (d.pairing) return "pairing…"
        if (d.state === BluetoothDeviceState.Connecting) return "connecting…"
        if (d.state === BluetoothDeviceState.Disconnecting) return "disconnecting…"
        if (d.connected) return d.batteryAvailable ? Math.round(d.battery * 100) + "%" : "connected"
        return d.paired ? "paired" : ""
    }

    readonly property var paired: devices.filter(d => d.paired || d.connected)
    readonly property var found: devices.filter(d => !d.paired && !d.connected)
    readonly property bool scanning: adapter ? adapter.discovering : false
    panelWidth: 340

    PanelHeader {
        title: "Bluetooth"
        detail: p.on ? "" : "off"
        showToggle: true
        toggle.on: p.on
        onToggled: (on) => Bt.power(on)
        actions: [
            IconButton {
                visible: p.on
                icon: "bluetooth_searching"
                active: p.scanning
                onClicked: if (p.adapter) p.adapter.discovering = !p.adapter.discovering
            }
        ]
    }

    EmptyState {
        visible: !p.on
        icon: "bluetooth_disabled"; text: "Bluetooth is off"; hint: "Turn it on with the switch above"
    }

    PanelSection { visible: p.on && p.paired.length > 0; text: "My devices" }
    Column {
        width: parent.width; spacing: 2
        visible: p.on
        Repeater {
            model: p.paired
            PanelRow {
                required property var modelData
                icon: p.icon(modelData)
                title: modelData.name || modelData.deviceName
                subtitle: modelData.connected ? "Connected" + (modelData.batteryAvailable ? " · battery " + Math.round(modelData.battery * 100) + "%" : "")
                                              : p.state(modelData) || "Not connected"
                active: modelData.connected
                busy: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting
                onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
                onRightClicked: modelData.forget()
            }
        }
    }

    PanelSection { visible: p.on && (p.found.length > 0 || p.scanning); text: "Nearby"; detail: p.scanning ? "searching…" : "" }
    Column {
        width: parent.width; spacing: 2
        visible: p.on
        Repeater {
            model: p.found.slice(0, 8)
            PanelRow {
                required property var modelData
                icon: p.icon(modelData)
                title: modelData.name || modelData.deviceName
                subtitle: modelData.pairing ? "Pairing…" : "Click to pair"
                busy: modelData.pairing
                onClicked: modelData.pair()
            }
        }
    }
    EmptyState {
        visible: p.on && p.devices.length === 0
        icon: p.scanning ? "bluetooth_searching" : "bluetooth"
        text: p.scanning ? "Looking for devices…" : "No devices yet"
        hint: p.scanning ? "Put the device in pairing mode" : "Search with the button above"
    }

    PanelDivider {}
    Row {
        width: parent.width; spacing: 8; layoutDirection: Qt.RightToLeft
        PanelButton { text: "Bluetooth settings"; icon: "settings"; onClicked: { Quickshell.execDetached(["blueman-manager"]); Panels.close() } }
    }
}
