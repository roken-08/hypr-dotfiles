#!/usr/bin/env bash
# shell.sh — start or restart the desktop shell (bar, notifications, wallpaper).
#
#   shell.sh start      at session start (autostart.lua)
#   shell.sh restart    SUPER+CTRL+R and Menu > Settings > Restart shell: the way
#                       back when the shell hangs or its bar is gone
#
# ORRERY_SHELL picks the bar: "quickshell" (default) or "waybar" (the classic
# config kept as a fallback). Set it in modules/autostart.lua.
set -u
which="${ORRERY_SHELL:-quickshell}"

# Quickshell runs as "qs" or, started by its full name, "quickshell": stop
# both, and wait until they are gone, or the new one starts beside the old
# and every screen gets two bars.
shell_pids() { pgrep -x qs; pgrep -x quickshell; }

# qs cannot draw anything before the compositor socket exists, and
# hyprland.start can fire a beat early; a failed start used to vanish into
# /dev/null, leaving no bar and no wallpaper with nothing to read.
SHELL_LOG="$HOME/.cache/orrery-shell.log"
wait_for_hyprland() {
    for _ in $(seq 1 25); do
        hyprctl version >/dev/null 2>&1 && return 0
        sleep 0.2
    done
}
# Start qs once and retry if it dies straight away. Qt has segfaulted during
# QML incubation at start-up on this machine (~/.cache/quickshell/crashes),
# so one lost race should not cost the whole session its bar.
start_qs() {
    [[ -n "$(shell_pids)" ]] && return 0
    wait_for_hyprland
    for attempt in 1 2 3; do
        echo "shell.sh: starting qs (attempt $attempt) $(date '+%F %T')" >>"$SHELL_LOG"
        setsid -f qs >/dev/null 2>>"$SHELL_LOG"
        sleep 2
        [[ -n "$(shell_pids)" ]] && return 0
        echo "shell.sh: qs exited on attempt $attempt" >>"$SHELL_LOG"
        sleep 1
    done
    return 1
}
stop() {
    pkill -x hypridle 2>/dev/null
    pkill -x qs 2>/dev/null
    pkill -x quickshell 2>/dev/null
    for _ in 1 2 3 4 5 6 7 8 9 10; do [[ -z "$(shell_pids)" ]] && break; sleep 0.2; done
    [[ -n "$(shell_pids)" ]] && { pkill -9 -x qs; pkill -9 -x quickshell; } 2>/dev/null
    pkill -f '^/usr/bin/wl-paste --watch echo' 2>/dev/null   # the shell's clipboard watcher (Services/Clip)
    pkill -x waybar 2>/dev/null
    pkill -x swaync 2>/dev/null
}

start() {
    pkill -x hypridle 2>/dev/null
    case "$which" in
        waybar)
            setsid -f hypridle -c "$HOME/.config/hypr/hypridle-classic.conf" >/dev/null 2>&1
            setsid -f swaync >/dev/null 2>&1      # the shell has its own notifications
            setsid -f waybar >/dev/null 2>&1
            # the classic setup needs a wallpaper daemon; the shell draws its own
            pgrep -x awww-daemon >/dev/null 2>&1 || setsid -f awww-daemon >/dev/null 2>&1
            (sleep 0.6; "$HOME/.local/bin/orrery-wall" apply) >/dev/null 2>&1 &
            ;;
        *)
            pkill -x awww-daemon 2>/dev/null
            setsid -f hypridle >/dev/null 2>&1    # logind bridge only (hypridle.conf)
            start_qs   # never a second one
            ;;
    esac
}

case "${1:-start}" in
    start)   start ;;
    restart) stop; start ;;
    stop)    stop ;;
    *) echo "usage: $0 start|restart|stop" >&2; exit 1 ;;
esac
