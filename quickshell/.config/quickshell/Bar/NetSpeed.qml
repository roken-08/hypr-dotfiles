import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Live download / upload speed, summed over the real network interfaces
// (loopback, bridges, containers and VPN tunnels are left out so traffic is
// not counted twice). Read from /proc/net/dev once a second. Click opens
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
    // "0K" "12K" "123K" "1.2M" "12M" "123M" "1.2G": at most 4 characters
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

    gap: pillMode ? 13 : 8
    Row { spacing: 2
          Icon { anchors.verticalCenter: parent.verticalCenter; icon: "arrow_downward"; color: ns.busy ? Theme.c.accentBright : Theme.c.accentLight }
          Label { anchors.verticalCenter: parent.verticalCenter; visible: !ns.vertical; text: ns.fmt(ns.down); color: Theme.c.accentLight } }
    Row { visible: !ns.vertical; spacing: 2
          Icon { anchors.verticalCenter: parent.verticalCenter; icon: "arrow_upward"; color: Theme.c.accentLight }
          Label { anchors.verticalCenter: parent.verticalCenter; text: ns.fmt(ns.up); color: Theme.c.accentLight } }
}
