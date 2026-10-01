pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

// Which app a media player belongs to. A browser reports itself ("Mozilla
// firefox") even when the music plays in a web app window: here each MPRIS
// bus name is traced to its process, that process to its window, and the
// window's class to its launcher (a web app's StartupWMClass), for the
// app's own name and icon.
Singleton {
    id: root
    property var classes: ({})      // dbus name -> window class

    function entryFor(player) {
        if (!player) return null
        const cls = classes[player.dbusName]
        if (!cls) return null
        const low = cls.toLowerCase()
        for (const a of DesktopEntries.applications.values)
            if ((a.startupClass || "").toLowerCase() === low || a.id.toLowerCase() === low) return a
        return null
    }
    function name(player) {
        const e = entryFor(player)
        return e ? e.name : (player ? (player.identity || player.desktopEntry || "") : "")
    }
    function icon(player) {
        const e = entryFor(player)
        if (e && e.icon) return Quickshell.iconPath(e.icon, true)
        return player && player.desktopEntry ? Quickshell.iconPath(player.desktopEntry, true) : ""
    }

    function refresh() { if (!trace.running) trace.running = true }
    Connections { target: Mpris.players; function onValuesChanged() { root.refresh() } }
    Component.onCompleted: refresh()
    // windows come and go while a player lives on (a web app opened after its tab)
    Timer { interval: 15000; repeat: true; running: Mpris.players.values.length > 0; onTriggered: root.refresh() }

    Process {
        id: trace
        command: ["sh", "-c",
            "hyprctl -j clients 2>/dev/null > \"${XDG_RUNTIME_DIR:-/tmp}/orrery-mpris-clients.json\"; " +
            "busctl --user list --no-legend 2>/dev/null | awk '$1 ~ /^org\\.mpris\\.MediaPlayer2\\./ && $2 ~ /^[0-9]+$/ {print $1, $2}' | " +
            "while read -r n p; do c=$(jq -r --argjson p \"$p\" 'first(.[] | select(.pid == $p) | .class) // empty' \"${XDG_RUNTIME_DIR:-/tmp}/orrery-mpris-clients.json\"); " +
            "[ -n \"$c\" ] && printf '%s\\t%s\\n' \"$n\" \"$c\"; done"]
        stdout: StdioCollector { onStreamFinished: {
            const m = {}
            for (const line of text.split("\n")) { const t = line.split("\t"); if (t.length === 2) m[t[0]] = t[1] }
            root.classes = m
        } }
    }
}
