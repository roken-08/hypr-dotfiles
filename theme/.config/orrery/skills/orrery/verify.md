# Verify — look at what you changed

The rice was built by measuring screenshots, not by trusting code. Every
visual change ends with a capture you read.

```bash
SP=${SCRATCH:-/tmp/orrery-check}; mkdir -p "$SP"
grim -s 0.6 "$SP/full.png"                       # whole screen, scaled (fast to read)
grim "$SP/full.png" && ffmpeg -y -loglevel error -i "$SP/full.png" \
     -vf "crop=1100:900:iw-1100:0" "$SP/topright.png"   # a crop, e.g. a panel under the bar
```
Then **read the PNG** (Read tool) and compare against what you meant. For
pixel questions convert to raw grey and measure runs (`ffmpeg -i x.png -f
rawvideo -pix_fmt gray -` + a few lines of python) instead of eyeballing.

## Drive the shell without the mouse

```bash
qs ipc call launcher toggle | picker theme | picker wallpaper | clipboard open | powermenu toggle
qs ipc call panels open audio|network|bluetooth|power|agents|notifications ; qs ipc call panels close
qs ipc call notifications test ; qs ipc call bar toggle ; qs ipc call bar position left|top
orrery-theme set zenith ; orrery-theme set eclipse      # dark/light
sleep 1.5 between opening and capturing (animations, async images)
```
Open a real app for app theming: `orrery-float btop` / `orrery-float nvim <file>`
(it opens its own kitty, class `orrery-float`, centred and big enough for btop —
do **not** wrap a `kitty` inside it), `thunar &`; then `hyprctl dispatch
focuswindow class:orrery-float`. Close it after by pid — `closewindow address:…`
is rejected by the lua dispatcher on this Hyprland:

```bash
for p in $(hyprctl clients -j | jq -r '.[] | select(.class=="orrery-float") | .pid'); do kill $p; done
```
and confirm `hyprctl clients -j | jq -r '.[].class'` lists none left.

Pointer/keyboard input (drags, arrow keys) can't be driven by `qs ipc`. A tiny
python uinput device works when `/dev/uinput` is writable (EV_KEY BTN_LEFT +
arrow keys, EV_REL X/Y; `UI_DEV_SETUP` + `UI_DEV_CREATE`, wait ~1 s before the
first event). Place the cursor with `hyprctl dispatch 'hl.dsp.cursor.move({x=…,y=…})'`.
Relative motion is accelerated, so read `hyprctl cursorpos` after a drag
before judging the result. Injected keys go to whatever has focus — ask
before using it while the user is at the keyboard.

## Code checks before shipping

- QML: `/usr/lib/qt6/bin/qmllint --json out.json **/*.qml` (Qt 6's linter;
  `/usr/bin/qmllint` is Qt 5's syntax checker and rejects Qt 6 syntax such as
  `function f(): void`, printing nothing but exit 255). Most warnings are
  Quickshell types it can't see; read `missing-property` on enums
  (e.g. `WifiSecurityType.None` doesn't exist: it's `Open`/`Owe`), `required`
  and `incompatible-type`. Then `qs log` after a restart must be quiet.
- Shell/Python/Lua: `bash -n`, `python3 -m py_compile`, `luac -p` on every
  tracked file; `jq empty` on JSON.
- Runtime: every `orrery-*` read-only mode (`list`, `current`, no-argument
  forms) exits 0; `orrery-menu-data | jq` has keybindings and an `about.rice`
  value (both read the repo).
- `./install.sh --dry-run --no-logout </dev/null` must change nothing and end
  with "nothing was changed".
- `qs ipc call menu run <id>` *runs* the entry's action (it opened the theme
  picker once during a check); to look at a page use `menu open <id>`.

## The checklist for "check the rice" / a new theme

For **dark and light**: bar (all three skins: pill/Legacy, floating, minimal), launcher, clipboard, a
notification popup + the bell's list, audio/network/power/agents panels,
picker (theme + wallpaper), power menu, kitty with fastfetch, btop, nvim,
Thunar, one Qt app, VS Code, the lock screen (rule 5 in SKILL.md — a lock
capture needs the user present; the SDDM greeter shares its layout).

Flag: text below ~3:1 contrast, colour that is not grey in a mono theme (except git) or
a grey where the stock upstream theme has a colour in a hued theme (btop boxes, lock fail), corners
not 4px / missing 1px border, glyph boxes (font), clipped or overlapping
text, anything that differs between the two themes in *layout*.

## Comparing against a reference

When asked for "identical to X": capture both at the same scale, crop the
same region, measure heights/widths/paddings numerically, and iterate until
the numbers match; a 1px text-height difference between GTK and Qt hinting
is the known floor.

Put the user's theme back (`orrery-theme set <the one from orrery-theme current at start>`)
and close anything you opened. Save it *before* the first switch
(`T0=$(orrery-theme current)`): the engine keeps no history, so once you have
switched there is no way to find out which theme it was.

## All themes at once

For a UI change, capture every panel (`qs ipc call panels open <name>`) and
overlay (menu, launcher, clipboard, power menu, picker, OSD) in all four
shipped themes on a spare workspace, at full resolution (`grim` without
`-s`; the screen is 2560 px, crop in those pixels), and read them as sheets
per theme. Save the theme first and put it back; clear the notifications the
theme switches leave. An edit that hot-reloads mid-capture can leave the
shell "Not ready to accept queries": `shell.sh restart` before capturing.
Opening the agents panel fetches usage (throttled to 2 min); many opens in a
row used to hit the API's rate limit (429).

## Rating a look

When asked to rate (or when making a theme), score 1–10 per surface and per
criterion, from screenshots you took, and write the table:

| | Contrast | Fits the wallpaper | Harmony | Accent use | Overall |

Contrast is measured, not guessed. With `colors.toml` in `$T`:

```python
import tomllib; c = tomllib.load(open(T, "rb"))["colors"]
def L(h):
    v = [int(h[i:i+2], 16) / 255 for i in (1, 3, 5)]
    v = [x / 12.92 if x <= 0.03928 else ((x + 0.055) / 1.055) ** 2.4 for x in v]
    return 0.2126 * v[0] + 0.7152 * v[1] + 0.0722 * v[2]
cr = lambda a, b: (max(L(a), L(b)) + 0.05) / (min(L(a), L(b)) + 0.05)
# targets: fg/bg0 ≥ 12, accent_light/bg0 ≥ 7, accent_mid/bg0 ≥ 4.5,
# accent_dim/bg0 ≥ 3, accent_bright/bg2 ≥ 7, every hue/bg0 ≥ 4.5
```

Then change what scored lowest and do it again: at least three rounds, until
Overall is 9 or more. Be honest in the scores; say what keeps it from a 10.

