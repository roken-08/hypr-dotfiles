#!/usr/bin/env bash
# The GPU half of the bar's sysmon (CPU and memory are read from /proc by
# Bar/SysMon.qml itself):
#   sysmon.sh gpu-source   once: a sysfs gpu_busy_percent file, "nvidia", or "none"
#   sysmon.sh gpu          NVIDIA only: the busy percent, or nothing while the
#                          card sleeps (polling a suspended laptop dGPU wakes it
#                          up and costs battery; the widget then hides its GPU half)
set -u
case "${1:-}" in
    gpu-source)
        for f in /sys/class/drm/card*/device/gpu_busy_percent; do
            [[ -r "$f" ]] && { echo "$f"; exit 0; }
        done
        if command -v nvidia-smi >/dev/null 2>&1; then
            for d in /sys/class/drm/card*/device; do
                [[ "$(cat "$d/vendor" 2>/dev/null)" == "0x10de" ]] && { echo nvidia; exit 0; }
            done
        fi
        echo none ;;
    gpu)
        for d in /sys/class/drm/card*/device; do
            [[ "$(cat "$d/vendor" 2>/dev/null)" == "0x10de" ]] || continue     # NVIDIA
            [[ "$(cat "$d/power_state" 2>/dev/null)" == "D0" ]] || exit 0      # asleep: leave it alone
            g="$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1)"
            [[ "$g" =~ ^[0-9]+$ ]] && echo "$g"
            exit 0
        done ;;
    *) echo "usage: sysmon.sh gpu-source|gpu" >&2; exit 1 ;;
esac
