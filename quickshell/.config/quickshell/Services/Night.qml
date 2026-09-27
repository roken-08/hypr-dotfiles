pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Night light — a warm screen tint, run by hyprsunset. The daemon is the
// state: it is either running (on) or not. hypr-nightlight does the work so
// the keybind, the menu and the bar widget all behave the same.
Singleton {
    id: root
    property bool on: false
    property bool available: true
    readonly property int temp: 4000

    function toggle() { run(["toggle"]) }
    function set(want) { run([want ? "on" : "off"]) }
    function run(args) { proc.command = [Quickshell.env("HOME") + "/.local/bin/hypr-nightlight"].concat(args); proc.running = true }

    Process { id: proc }   // hypr-nightlight reports the new state itself
    Process {
        id: poll
        command: ["bash", "-c", "command -v hyprsunset >/dev/null || { echo missing; exit 0; }; pgrep -x hyprsunset >/dev/null && echo on || echo off"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const s = text.trim()
                root.available = s !== "missing"
                root.on = s === "on"
            }
        }
    }
    Timer { interval: 10000; running: true; repeat: true; onTriggered: poll.running = true }

    IpcHandler {
        target: "nightlight"
        function toggle(): bool { root.toggle(); return !root.on }
        function on(): void { root.set(true) }
        function off(): void { root.set(false) }
        // set by hypr-nightlight when it changes the state (no 10 s wait)
        function state(s: string): void { if (s === "on" || s === "off") root.on = s === "on" }
        function status(): string { return !root.available ? "hyprsunset not installed" : root.on ? "on" : "off" }
    }
}
