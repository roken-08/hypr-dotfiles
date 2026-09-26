import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Live download / upload speed, summed over the real network interfaces
// (loopback, bridges, containers and VPN tunnels are left out so traffic is
// not counted twice). Read from /proc/net/dev once a second; the numbers
// keep a fixed width so the bar does not shift as they change. Click opens
// the network panel.
Pill {
    id: ns
    property real down: 0          // bytes per second
    property real up: 0
    property var last: null         // { rx, tx, t }
    readonly property bool busy: down + up > 1024 * 1024
    onClicked: Quickshell.execDetached(["qs", "ipc", "call", "panels", "open", "network"])

    // virtual interfaces: skip, their traffic also crosses a real one
    function virtual(name) { return /^(lo|veth|docker|br-|virbr|vnet|tun|tap|wg|tailscale|zt)/.test(name) }
    function sample(text) {
        let rx = 0, tx = 0
        for (const line of text.split("\n").slice(2)) {
            const c = line.indexOf(":")
            if (c < 0) continue
            const name = line.slice(0, c).trim()
            if (virtual(name)) continue
            const f = line.slice(c + 1).trim().split(/\s+/)
            rx += +f[0]; tx += +f[8]
        }
        const t = Date.now()
        if (last && t > last.t) {
            const dt = (t - last.t) / 1000
            down = Math.max(0, (rx - last.rx) / dt)
            up = Math.max(0, (tx - last.tx) / dt)
        }
        last = { rx: rx, tx: tx, t: t }
    }
    // "0K" "12K" "123K" "1.2M" "12M" "123M" "1.2G": at most 4 characters, shown
    // left-aligned next to the arrow in a box 4 digits wide, so nothing shifts
    function fmt(b) {
        const k = b / 1024
        let s
        if (k < 1000) s = Math.round(k) + "K"
        else if (k < 1024 * 10) s = (k / 1024).toFixed(1) + "M"
        else if (k < 1024 * 1000) s = Math.round(k / 1024) + "M"
        else s = (k / 1024 / 1024).toFixed(1) + "G"
        return s
    }

    FileView { id: dev; path: "/proc/net/dev"; blockLoading: true }
    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { dev.reload(); ns.sample(dev.text()) }
    }

    Icon { icon: "arrow_downward"; color: ns.busy ? Theme.c.accentBright : Theme.c.accentLight }
    TextMetrics { id: wide; font.family: Theme.font; font.pixelSize: Theme.fontSize; font.weight: Font.Medium; text: "8.8M" }
    Label { visible: !ns.vertical; width: wide.width; text: ns.fmt(ns.down); color: Theme.c.accentLight }
    Icon { visible: !ns.vertical; icon: "arrow_upward"; color: Theme.c.accentLight }
    Label { visible: !ns.vertical; width: wide.width; text: ns.fmt(ns.up); color: Theme.c.accentLight }
}
