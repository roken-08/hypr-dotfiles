import QtQuick

// The shell's arrival for a centred card (menu, launcher, clipboard, picker):
// whenever `when` turns true the target scales up from 96% and fades in,
// Material 3 Expressive "default spatial" for the scale, "effects" for the
// fade. Only the card moves: the full-screen layer behind it just fades
// (Hyprland), so the backdrop and its blur never zoom.
Item {
    id: a
    required property Item target
    property bool when: false
    property real from: 0.96
    onWhenChanged: if (when && target) { anim.stop(); target.scale = from; target.opacity = 0; anim.start() }
    ParallelAnimation {
        id: anim
        NumberAnimation { target: a.target; property: "scale"; to: 1; duration: Motion.growMs
                          easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.growCurve }
        NumberAnimation { target: a.target; property: "opacity"; to: 1; duration: Motion.effectsMs
                          easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.fadeCurve }
    }
}
