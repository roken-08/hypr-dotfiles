pragma Singleton
import QtQuick
import Quickshell

// The shell's one motion language. Every surface that appears, grows or
// leaves uses these, so the whole desktop moves alike.
//   in:  a surface arriving: fast start, long soft landing (Material 3
//        "emphasized decelerate")
//   out: leaving: gentle start, quick finish ("emphasized accelerate"),
//        shorter than in, so closing never feels like waiting
//   move: something already on screen changing size or place ("standard")
//   fade: colour and opacity alongside a move (M3 Expressive "effects")
// Curves are cubic beziers for Easing.BezierSpline (x1 y1 x2 y2 1 1).
Singleton {
    readonly property int inMs: 320
    readonly property int outMs: 180
    readonly property int moveMs: 250
    readonly property int fadeMs: 200
    readonly property var inCurve:   [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property var outCurve:  [0.3, 0, 0.8, 0.15, 1, 1]
    readonly property var moveCurve: [0.2, 0, 0, 1, 1, 1]
    readonly property var fadeCurve: [0.34, 0.8, 0.34, 1, 1, 1]
}
