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

# Start qs under a supervisor: it cannot draw anything before the compositor
# socket exists (hyprland.start can fire a beat early), and it has segfaulted
# both at login and mid-session (Qt6QmlModels /
# QQmlIncubatorPrivate::incubate, see ~/.cache/quickshell/crashes). A dead
# shell means no bar and no wallpaper until someone runs `shell.sh restart`,
# so it is restarted with backoff, and stays down only after `shell.sh stop`.
# Its output used to go to /dev/null: now it lands in SHELL_LOG.
SHELL_LOG="$HOME/.cache/orrery-shell.log"
STOP_FLAG="${XDG_RUNTIME_DIR:-/tmp}/orrery-shell.stop"
SUP_PID="${XDG_RUNTIME_DIR:-/tmp}/orrery-shell.pid"
sup_pid() { [[ -s "$SUP_PID" ]] && kill -0 "$(<"$SUP_PID")" 2>/dev/null && cat "$SUP_PID"; }
# Every decision is logged from now on: the last silent start-at-login was
# invisible (no bar, no wallpaper, empty log), so start_qs() no longer returns
# quietly.
say() { echo "shell.sh: $* $(date '+%F %T')" >>"$SHELL_LOG"; }

# systemd owns the shell when this unit is installed (it is, by install.sh):
# a real Restart=always, `systemctl --user status orrery-shell` for diagnosis,
# and a start that cannot be lost to Hyprland's exec-at-login race.
UNIT=orrery-shell.service
have_unit() { systemctl --user cat "$UNIT" >/dev/null 2>&1; }
wait_for_hyprland() {
    for _ in $(seq 1 25); do
        hyprctl version >/dev/null 2>&1 && return 0
        sleep 0.2
    done
}
supervise() {
    local fails=0 delay=1 started ran
    echo $$ >"$SUP_PID"
    rm -f "$STOP_FLAG"
    while [[ ! -e "$STOP_FLAG" ]]; do
        if [[ -n "$(shell_pids)" ]]; then sleep 2; continue; fi
        [[ -e "$STOP_FLAG" ]] && break
        wait_for_hyprland
        started=$(date +%s)
        echo "--- shell.sh: starting qs $(date '+%F %T')" >>"$SHELL_LOG"
        qs >>"$SHELL_LOG" 2>&1
        ran=$(( $(date +%s) - started ))
        echo "--- shell.sh: qs exited ($?) after ${ran}s $(date '+%F %T')" >>"$SHELL_LOG"
        [[ -e "$STOP_FLAG" ]] && break
        if (( ran > 60 )); then fails=0; delay=1; else fails=$((fails + 1)); fi
        if (( fails >= 10 )); then
            echo "shell.sh: qs died 10 times in a row, giving up" >>"$SHELL_LOG"
            exit 1
        fi
        sleep "$delay"
        delay=$(( delay < 30 ? delay * 2 : 30 ))
    done
    rm -f "$SUP_PID"
}
start_qs() {
    local running sup
    running=$(shell_pids)
    [[ -n "$running" ]] && { say "qs already running (pid $running), nothing to do"; return 0; }
    sup=$(sup_pid)
    [[ -n "$sup" ]] && { say "supervisor already running (pid $sup), nothing to do"; return 0; }
    rm -f "$STOP_FLAG"
    say "starting supervisor"
    setsid -f "$0" supervise >/dev/null 2>&1
}
stop() {
    if have_unit; then
        say "stopping $UNIT"
        systemctl --user stop "$UNIT" >/dev/null 2>&1
    fi
    touch "$STOP_FLAG"                      # tell the supervisor to stay down
    local sup; sup=$(sup_pid)
    [[ -n "$sup" ]] && kill "$sup" 2>/dev/null
    rm -f "$SUP_PID"
    pkill -x hypridle 2>/dev/null
    pkill -x qs 2>/dev/null
    pkill -x quickshell 2>/dev/null
    for _ in 1 2 3 4 5 6 7 8 9 10; do [[ -z "$(shell_pids)" ]] && break; sleep 0.2; done
    [[ -n "$(shell_pids)" ]] && { pkill -9 -x qs; pkill -9 -x quickshell; } 2>/dev/null
    pkill -f '^/usr/bin/wl-paste --watch echo' 2>/dev/null   # the shell's clipboard watcher (Services/Clip)
    rm -f "$STOP_FLAG"
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
            if have_unit; then
                say "starting $UNIT via systemd"
                systemctl --user reset-failed "$UNIT" >/dev/null 2>&1
                systemctl --user start "$UNIT" >>"$SHELL_LOG" 2>&1 \
                    || say "systemctl start $UNIT failed ($?), falling back to the supervisor"
                systemctl --user is-active --quiet "$UNIT" && { say "shell up (systemd)"; return 0; }
            fi
            start_qs   # never a second one
            ;;
    esac
}

case "${1:-start}" in
    start)   start ;;
    restart) stop; start ;;
    stop)    stop ;;
    supervise) supervise ;;          # internal: the watchdog loop, see start_qs
    *) echo "usage: $0 start|restart|stop" >&2; exit 1 ;;
esac
