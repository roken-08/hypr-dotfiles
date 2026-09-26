import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons
import qs.Services

// Power menu — a faithful port of the wlogout layout + style:
// five 190x174 buttons 38px apart, centred; Material Symbols icons in the
// button's text colour (inverted on the light hover fill, like wlogout's
// rest/hover PNGs were); first button focused; keys l o h r s,
// arrows + Enter, Escape. The backdrop is blurred by the Hyprland layer
// rule for the "hypr-powermenu" namespace, like wlogout's was.
Scope {
    id: scope
    property bool open: false
    property int focused: 0
    onOpenChanged: if (open) focused = 0

    IpcHandler {
        target: "powermenu"
        function toggle(): void { scope.open = !scope.open }
        function close(): void { scope.open = false }
    }

    readonly property var actions: [
        { key: "l", icon: "lock",               run: () => { scope.open = false; Lock.lock() } },
        { key: "o", icon: "logout",             run: () => Hyprland.dispatch(Hyprland.usingLua ? "hl.dsp.exit()" : "exit") },
        { key: "h", icon: "bedtime",            run: () => { scope.open = false; Quickshell.execDetached(["systemctl", "suspend"]) } },
        { key: "r", icon: "restart_alt",        run: () => Quickshell.execDetached(["systemctl", "reboot"]) },
        { key: "s", icon: "power_settings_new", run: () => Quickshell.execDetached(["systemctl", "poweroff"]) }
    ]

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            visible: scope.open
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: scope.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            WlrLayershell.namespace: "hypr-powermenu"
            // window { background-color: alpha(@bg0, 0.7) }
            color: Theme.alpha(Theme.c.bg0, 0.7)

            MouseArea { anchors.fill: parent; onClicked: scope.open = false }

            Item {
                anchors.fill: parent
                focus: scope.open
                Keys.onPressed: (e) => {
                    if (e.key === Qt.Key_Escape) { scope.open = false; return }
                    if (e.key === Qt.Key_Left || (e.key === Qt.Key_Tab && e.modifiers & Qt.ShiftModifier)) { scope.focused = (scope.focused + 4) % 5; return }
                    if (e.key === Qt.Key_Right || e.key === Qt.Key_Tab) { scope.focused = (scope.focused + 1) % 5; return }
                    if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) { scope.actions[scope.focused].run(); return }
                    const a = scope.actions.find(x => x.key === e.text.toLowerCase())
                    if (a) a.run()
                }
                Row {
                    anchors.centerIn: parent
                    spacing: 38
                    Repeater {
                        model: scope.actions
                        Rectangle {
                            id: btn
                            required property var modelData
                            required property int index
                            readonly property bool hov: m.containsMouse
                            readonly property bool foc: scope.focused === index
                            width: 190; height: 174
                            radius: Theme.radius
                            // button / button:focus / button:hover from the wlogout css
                            color: hov ? Theme.c.fg : foc ? Theme.c.bg2 : Theme.c.bg1
                            border.width: 1
                            border.color: hov ? Theme.c.fg : foc ? Theme.c.borderStrong : Theme.c.border
                            Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            Behavior on border.color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            Icon {
                                anchors.centerIn: parent
                                icon: btn.modelData.icon
                                size: 64
                                color: btn.hov ? Theme.c.bg0 : btn.foc ? Theme.c.fg : Theme.c.accentLight
                            }
                            MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onEntered: scope.focused = btn.index
                                        onClicked: btn.modelData.run() }
                        }
                    }
                }
            }
        }
    }
}
