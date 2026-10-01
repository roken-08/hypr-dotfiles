import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import qs.Commons
import qs.Bar

// Sound: output and input, each a volume line and a short device picker,
// then the apps playing right now with their own volume.
Panel {
    id: p
    name: "audio"
    panelWidth: 340

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
    readonly property var sources: Pipewire.nodes.values.filter(n => !n.isSink && !n.isStream && n.audio && n.type === PwNodeType.AudioSource)
    // every playback stream is tracked (a node's properties and volume are
    // only filled in once tracked); the list shows the apps, not the plumbing
    // (echo cancellation, speech-dispatcher's dummy)
    // (a playback stream is isSink in Quickshell: it flows into a sink)
    readonly property var streams: Pipewire.nodes.values.filter(n => n.isStream && n.isSink)
    readonly property var appStreams: streams.filter(n => n.audio && p.appName(n) !== "" && !/echo-cancel|speech-dispatcher|dummy/i.test(n.name))
    // one row per app, whatever number of streams it has open (a browser has several)
    readonly property var apps: {
        const out = [], at = {}
        for (const n of appStreams) {
            const a = p.appName(n)
            if (at[a] === undefined) { at[a] = out.length; out.push({ name: a, streams: [], node: n }) }
            out[at[a]].streams.push(n)
        }
        return out
    }
    PwObjectTracker { objects: [p.sink, p.source].concat(p.streams) }

    function label(n) { return n ? (n.nickname || n.description || n.name) : "—" }
    function appName(n) { return (n.properties && n.properties["application.name"]) || "" }
    // what kind of device it is, from its name
    function devIcon(n, input) {
        const s = ((n && n.name) || "") + " " + ((n && n.description) || "")
        if (/bluez/i.test(s)) return input ? "headset_mic" : "headphones"
        if (/hdmi|displayport/i.test(s)) return "tv"
        if (/headphone|headset/i.test(s)) return input ? "headset_mic" : "headphones"
        if (/usb/i.test(s)) return "usb"
        return input ? "mic" : "speaker"
    }

    PanelHeader {
        title: "Sound"
        actions: [ IconButton { icon: "tune"; onClicked: { Quickshell.execDetached(["pavucontrol"]); Panels.close() } } ]
    }

    PanelSection { text: "Output" }
    VolumeLine { node: p.sink }
    DeviceList {
        model: p.sinks; current: p.sink
        icon: (n) => p.devIcon(n, false); label: (n) => p.label(n)
        onPicked: (n) => Pipewire.preferredDefaultAudioSink = n
    }

    PanelDivider {}
    PanelSection { text: "Input" }
    VolumeLine { node: p.source; input: true }
    DeviceList {
        model: p.sources; current: p.source
        icon: (n) => p.devIcon(n, true); label: (n) => p.label(n)
        onPicked: (n) => Pipewire.preferredDefaultAudioSource = n
    }

    PanelDivider { visible: p.apps.length > 0 }
    PanelSection { visible: p.apps.length > 0; text: "Apps" }
    Repeater {
        model: p.apps
        Item {
            id: app
            required property var modelData
            width: parent.width; height: 32
            readonly property var lead: modelData.node
            readonly property real level: lead && lead.audio ? lead.audio.volume : 0
            readonly property bool muted: lead && lead.audio ? lead.audio.muted : false
            // the app's icon: its own hint, else its desktop entry, else a note
            readonly property string iconName: {
                const pr = lead.properties || {}
                if (pr["application.icon-name"]) return pr["application.icon-name"]
                const e = DesktopEntries.heuristicLookup(pr["application.process.binary"] || modelData.name)
                          || DesktopEntries.heuristicLookup(modelData.name)
                return e ? e.icon : ""
            }
            // a move unmutes, as the output line does; the icon toggles mute
            function setAll(v) { for (const n of modelData.streams) if (n.audio) { n.audio.volume = v; if (v > 0) n.audio.muted = false } }
            function toggleMute() { const m = !muted; for (const n of modelData.streams) if (n.audio) n.audio.muted = m }
            Item {
                id: appIcon
                anchors.left: parent.left; anchors.leftMargin: 6; anchors.verticalCenter: parent.verticalCenter
                width: 28; height: 28
                IconImage {
                    id: img
                    anchors.centerIn: parent; implicitSize: 20
                    source: app.iconName !== "" ? Quickshell.iconPath(app.iconName, true) : ""
                    visible: source.toString() !== ""
                }
                Icon { anchors.centerIn: parent; visible: !img.visible; icon: "music_note"; size: Theme.fs(16); color: Theme.c.accentLight }
                opacity: app.muted ? 0.4 : 1
                // muted: a crossed speaker over the icon
                Rectangle {
                    visible: app.muted
                    anchors.right: parent.right; anchors.bottom: parent.bottom
                    width: 14; height: 14; radius: 7; color: Theme.c.bg0
                    Icon { anchors.centerIn: parent; icon: "volume_off"; size: Theme.fs(11); color: Theme.c.accentBright }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: app.toggleMute() }
            }
            Label {
                id: appLabel
                anchors.left: appIcon.right; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter
                width: 84; elide: Text.ElideRight
                text: app.modelData.name; font.pixelSize: Theme.fs(12); color: Theme.c.fg
            }
            Slider {
                anchors.left: appLabel.right; anchors.leftMargin: 8
                anchors.right: appPct.left; anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: undefined
                value: app.level; dimmed: app.muted
                onMoved: (x) => app.setAll(x)
            }
            Label {
                id: appPct
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                width: 38; horizontalAlignment: Text.AlignRight
                text: Math.round(app.level * 100) + "%"
                font.pixelSize: Theme.fs(12); color: Theme.c.accentLight
            }
        }
    }
}
