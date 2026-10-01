import QtQuick
import Quickshell
import qs.Commons
import qs.Services

// Night light: warm screen tint while it is on (hyprsunset). Click toggles;
// with hyprsunset missing the glyph stays dim and says so.
Pill {
    id: nl
    onClicked: {
        if (Night.available) Night.toggle()
        else Quickshell.execDetached(["notify-send", "-a", "night light", "hyprsunset is not installed", "sudo pacman -S hyprsunset"])
    }
    Icon {
        // on: the moon, bright; off: the crossed-out moon, dimmed
        icon: Night.on ? "nightlight" : "bedtime_off"
        color: Night.on && Night.available ? Theme.c.accentBright : Theme.c.accentDim
    }
}
