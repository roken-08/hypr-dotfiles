#!/usr/bin/env bash
# brightness.sh up|down [step%]   change the screen backlight (smoothly, never below 5%)
#                                 and show the shell's OSD
# brightness.sh dim|restore       idle dimming (saves, then restores the level)
# brightness.sh kbd-off|kbd-restore   keyboard backlight, if there is one
#
# Devices are detected, not hardcoded: the first backlight that is not the
# NVIDIA stub (it reports a constant 100%), and any *kbd_backlight LED.
set -u
dev="$(brightnessctl -l -m -c backlight 2>/dev/null | cut -d, -f1 | grep -v -i nvidia | head -n1)"
[[ -n "$dev" ]] || dev="$(brightnessctl -l -m -c backlight 2>/dev/null | cut -d, -f1 | head -n1)"
kbd="$(brightnessctl -l -m -c leds 2>/dev/null | cut -d, -f1 | grep kbd_backlight | head -n1)"
step="${2:-10}"
case "${1:-}" in
    up|down)
        [[ -n "$dev" ]] || exit 0
        max=$(brightnessctl -d "$dev" max)
        floor=$(( max * 5 / 100 )); (( floor < 1 )) && floor=1   # never 0: that turns the panel off
        # a press during a glide starts from where that glide is heading
        tfile="${XDG_RUNTIME_DIR:-/tmp}/orrery-brightness-target"
        from=$(brightnessctl -d "$dev" get); now=$(date +%s%N)
        read -r t when 2>/dev/null < "$tfile" || true   # "target nanoseconds"
        [[ ${t:-} =~ ^[0-9]+$ && ${when:-} =~ ^[0-9]+$ ]] && (( now - when < 400000000 )) && from=$t
        delta=$(( max * step / 100 ))
        [[ $1 == up ]] && target=$(( from + delta )) || target=$(( from - delta ))
        (( target > max )) && target=$max
        (( target < floor )) && target=$floor
        echo "$target $now" > "$tfile"
        command -v qs >/dev/null 2>&1 && qs ipc call osd brightness "$(( target * 100 / max ))" >/dev/null 2>&1 &
        # glide there in small steps (~120 ms); a newer press takes over
        cur=$(brightnessctl -d "$dev" get)
        for i in 1 2 3 4 5 6; do
            read -r t _ 2>/dev/null < "$tfile"; [[ ${t:-} == "$target" ]] || exit 0
            brightnessctl -q -d "$dev" set $(( cur + (target - cur) * i / 6 ))
            sleep 0.02
        done ;;
    dim)         [[ -n "$dev" ]] && brightnessctl -q -d "$dev" -s set 10% ;;
    restore)     [[ -n "$dev" ]] && brightnessctl -q -d "$dev" -r ;;
    kbd-off)     [[ -n "$kbd" ]] && brightnessctl -q -d "$kbd" -s set 0 ;;
    kbd-restore) [[ -n "$kbd" ]] && brightnessctl -q -d "$kbd" -r ;;
    *) echo "usage: $0 up|down [step] | dim|restore | kbd-off|kbd-restore" >&2; exit 1 ;;
esac
exit 0
