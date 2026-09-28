import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// CPU, memory and GPU use; click opens btop in the default terminal.
// CPU and memory are read from /proc here (no process per poll). The GPU
// source is found once by Services/sysmon.sh: a sysfs busy-percent file is
// read directly too; only an NVIDIA card needs the script per poll, and it
// leaves a sleeping laptop dGPU alone (the GPU half then hides).
Pill {
    id: sm
    property int cpu: 0
    property int mem: 0
    property int gpu: -1
    property var last: null
    property string gpuSource: ""      // "", "nvidia" or a sysfs file
    onClicked: Quickshell.execDetached(["sh", "-c", 'exec "${TERMINAL:-$(cat "$HOME/.config/orrery/defaults/terminal" 2>/dev/null || echo kitty)}" -e btop'])

    FileView { id: stat; path: "/proc/stat"; blockLoading: true }
    FileView { id: meminfo; path: "/proc/meminfo"; blockLoading: true }
    FileView { id: gpuFile; path: sm.gpuSource.startsWith("/") ? sm.gpuSource : ""; blockLoading: true }
    function sample() {
        stat.reload()
        const f = stat.text().split("\n", 1)[0].trim().split(/\s+/).slice(1).map(Number)   // user nice system idle iowait irq softirq steal
        const idle = f[3] + f[4], total = f.slice(0, 8).reduce((a, b) => a + b, 0)
        if (last && total > last.total) cpu = Math.round(100 * (1 - (idle - last.idle) / (total - last.total)))
        last = { idle: idle, total: total }
        meminfo.reload()
        const m = meminfo.text(), kb = k => { const x = m.match(new RegExp("^" + k + ":\\s+(\\d+)", "m")); return x ? +x[1] : 0 }
        const tot = kb("MemTotal")
        if (tot > 0) mem = Math.round(100 - 100 * kb("MemAvailable") / tot)
        if (gpuSource.startsWith("/")) { gpuFile.reload(); const g = parseInt(gpuFile.text()); gpu = isNaN(g) ? -1 : g }
        else if (gpuSource === "nvidia" && !nv.running) nv.running = true
    }
    Process {   // once: where the GPU load comes from
        command: ["bash", Quickshell.shellPath("Services/sysmon.sh"), "gpu-source"]
        running: true
        stdout: StdioCollector { onStreamFinished: sm.gpuSource = text.trim() === "none" ? "" : text.trim() }
    }
    Process {
        id: nv
        command: ["bash", Quickshell.shellPath("Services/sysmon.sh"), "gpu"]
        stdout: StdioCollector { onStreamFinished: { const g = parseInt(text); sm.gpu = isNaN(g) ? -1 : g } }
    }
    Timer { interval: 3000; running: true; repeat: true; triggeredOnStart: true; onTriggered: sm.sample() }
    readonly property color hot: Theme.hued ? Theme.c.warning : Theme.c.accentBright
    // each icon sits with its number; the pill's gap separates the pairs
    gap: pillMode ? 13 : 7
    // each reading keeps the width of "88%" (Reading.qml), so 5% → 12% doesn't
    // push the bar; in a side bar they stack, number under icon
    Reading { icon: "speed"; text: sm.cpu + "%"; iconColor: sm.cpu > 85 ? sm.hot : Theme.c.accentLight }
    Reading { icon: "sd_card"; text: sm.mem + "%"; iconColor: sm.mem > 85 ? sm.hot : Theme.c.accentLight }
    Reading { visible: sm.gpu >= 0; icon: "videogame_asset"; text: sm.gpu + "%"; iconColor: sm.gpu > 85 ? sm.hot : Theme.c.accentLight }
}
