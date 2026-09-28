#!/usr/bin/env bash
# screenshot.sh screen|region|window|pick
#   screen   the whole focused monitor
#   region   drag out a rectangle
#   window   the active window
#   pick     click a window to capture it
# Saved to ~/Pictures/screenshot/ and copied to the clipboard; a notification
# shows it. Esc during a selection cancels cleanly: nothing is saved.
set -u
dir="$HOME/Pictures/screenshot"
mkdir -p "$dir"
file="$dir/screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png"
n=2; while [[ -e $file ]]; do file="${file%.png}"; file="${file%-[0-9]}-$n.png"; n=$((n+1)); done   # two in one second

# rectangles of the windows on the visible workspaces, as slurp wants them
windows() {
    local ws
    ws="$(hyprctl -j monitors | jq -r '[.[].activeWorkspace.id] | join(",")')"
    hyprctl -j clients | jq -r --arg ws "$ws" '
        ($ws | split(",") | map(tonumber)) as $vis
        | .[] | select(.mapped and (.hidden | not) and (.workspace.id as $w | $vis | index($w)))
        | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'
}

case "${1:-}" in
    screen)
        mon="$(hyprctl -j monitors | jq -r '.[] | select(.focused) | .name')"
        grim ${mon:+-o "$mon"} "$file" ;;
    region)
        geom="$(slurp -d)" || exit 0          # Esc: nothing to do
        [[ -n $geom ]] || exit 0
        grim -g "$geom" "$file" ;;
    window)
        geom="$(hyprctl -j activewindow | jq -r 'if .at then "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])" else empty end')"
        [[ -n $geom ]] || { notify-send -a Screenshot "No window to capture"; exit 0; }
        grim -g "$geom" "$file" ;;
    pick)
        geom="$(windows | slurp -r)" || exit 0
        [[ -n $geom ]] || exit 0
        grim -g "$geom" "$file" ;;
    *) echo "usage: screenshot.sh screen|region|window|pick" >&2; exit 1 ;;
esac

if [[ -s $file ]]; then
    wl-copy --type image/png < "$file"
    notify-send -a Screenshot -i "$file" "Screenshot saved" "$(basename "$file") · copied to the clipboard"
else
    rm -f "$file"
    notify-send -a Screenshot -u critical "Screenshot failed" "grim could not capture the screen"
fi
