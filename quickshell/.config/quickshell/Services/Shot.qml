pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Screenshot mode, for pictures that get published (orrery-theme-preview):
// while `on`, the bar leaves out what is playing. `qs ipc call shot on|off`.
Singleton {
    id: root
    property bool on: false

    IpcHandler {
        target: "shot"
        function on(): void { root.on = true }
        function off(): void { root.on = false }
        function status(): string { return root.on ? "on" : "off" }
    }
}
