# hypr-dotfiles

A complete Hyprland desktop for Arch Linux: a **Lua-configured Hyprland** and a hand-built
**Quickshell** shell (bar, dock, launcher, menu, panels, notifications, lock screen, power menu)
with one theme engine that colours everything from a single palette. That covers GTK, Qt, kitty,
alacritty, Neovim, btop, VS Code, Firefox and the login screen too. Three themes ship with it,
one command installs it, and switching theme or bar style happens live.

![License: MIT](https://img.shields.io/badge/license-MIT-black)
![Hyprland 0.56](https://img.shields.io/badge/hyprland-0.56-black)
![Quickshell 0.3](https://img.shields.io/badge/quickshell-0.3-black)
![Config: Lua](https://img.shields.io/badge/config-lua-black)

---

## Themes

Switch any time with `SUPER` + `CTRL` + `SHIFT` + `SPACE` (a live carousel) or `hypr-theme set <name>`.

**HyprMono** (`hyprmono`): dark, greys only.

![HyprMono](Screenshots/hyprmono.jpg)

**HyprMono Light** (`hyprmono-light`): the same design on white.

![HyprMono Light](Screenshots/hyprmono-light.jpg)

**Catppuccin Mocha** (`catppuccin-mocha`): the official Mocha palette. Every app is coloured the
way its own Catppuccin port does it.

![Catppuccin Mocha](Screenshots/catppuccin-mocha.jpg)

### Launcher, menu and panels

| | HyprMono | HyprMono Light | Catppuccin Mocha |
|---|---|---|---|
| **Launcher** · `SUPER+D` | ![](Screenshots/launcher-hyprmono.jpg) | ![](Screenshots/launcher-hyprmono-light.jpg) | ![](Screenshots/launcher-catppuccin-mocha.jpg) |
| **Menu** · `SUPER+SPACE` | ![](Screenshots/menu-hyprmono.jpg) | ![](Screenshots/menu-hyprmono-light.jpg) | ![](Screenshots/menu-catppuccin-mocha.jpg) |
| **Power panel** · click the battery | ![](Screenshots/panel-hyprmono.jpg) | ![](Screenshots/panel-hyprmono-light.jpg) | ![](Screenshots/panel-catppuccin-mocha.jpg) |

---

## What you get

- **Bar**: three styles (Legacy pills, Floating, Minimal) on any screen edge. Drag it to move
  it, double-click to make it transparent. Widgets: workspaces, focused window, now playing,
  clock and calendar, tray, CPU/RAM/GPU, live network speed, coding-agent usage, night light,
  caffeine, Bluetooth, volume, Wi-Fi, battery, keyboard layout, notifications. Turn each one on
  or off from the menu.
- **Dock**: pinned apps, then whatever else is running. Always visible, auto-hide, or hidden
  only while a window covers it. Works on any edge.
- **Launcher** with fuzzy search and a launch history, and **clipboard history** with image
  previews.
- **The menu** (`SUPER+SPACE`): every setting in one searchable list. Theme, wallpaper, bar,
  dock, font, text size, display scale, toggles, Wi-Fi/Bluetooth/audio, keybindings, reminders,
  power.
- **Panels** under the bar for sound, Wi-Fi, Bluetooth and power profiles. There's also a
  volume/brightness OSD, notifications with a history and do-not-disturb, a **lock screen** and a
  **power menu**.
- **Theme engine**: `hypr-theme` renders one `colors.toml` into every app, dark and light.
  Themes you make stay on your machine.
- **Idle handling**: dim, lock, screen off and suspend on timers. **Caffeine** pauses them.
  **Night light** runs through hyprsunset.
- **Coding agents**: Claude Code usage in the bar, and a `/hypr` skill that lets an AI agent
  make themes and widgets or fix your setup safely.
- **Login screen**: an SDDM theme that matches the lock screen, running under Hyprland.

---

## Install

Arch Linux or an Arch-based distro (CachyOS, EndeavourOS…), on a Wayland-capable GPU.

```bash
sudo pacman -Syu --needed git
git clone https://github.com/thomasmartinoa/hypr-dotfiles.git ~/hypr-dotfiles
cd ~/hypr-dotfiles
./install.sh
```

Then **log out and pick Hyprland** on the login screen (or reboot).

The installer:

1. Installs every package the desktop uses, from the repos plus a few from the AUR (it offers
   to set up `yay`). If pacman fails because the system is half-upgraded, it explains that and
   offers `pacman -Syu`.
2. Moves any configs that are in the way into a backup folder, but only after asking.
3. Links everything into your home with GNU Stow, so the repo stays the source of truth.
4. Renders and applies the default theme.
5. Enables Bluetooth, power profiles and NetworkManager. NetworkManager is skipped if another
   network daemon is running.
6. Enables SDDM, unless you already use another login manager.
7. Installs the login-screen theme and a small root helper, so theme switches also reach the
   login screen and pkexec apps.

It is safe to run again, and it never overwrites without asking.

| Flag | Does |
|---|---|
| `--dry-run` | Show what would happen, change nothing |
| `--stow-only` | Skip package installation |
| `--migrate` / `--no-migrate` | Back up blocking files without asking / never move anything |
| `--skip-root` | Don't touch `/root`, SDDM or sudoers |
| `--no-aur` | Don't offer yay / AUR packages |
| `--no-logout` | Don't offer to log out at the end |

### After installing

- **Your monitor.** By default every screen gets its preferred mode, with the scale picked
  automatically. For an exact mode, refresh rate or scale, put a rule in
  `~/.config/hypr/modules/monitors.local.lua`. That file is yours and not part of the repo;
  `hyprctl monitors all` lists your outputs and modes. For example:
  `hl.monitor({ output = "eDP-1", mode = "2560x1440@165", position = "auto", scale = 1.6 })`.
  Menu › Style › Display scale saves there too.
- **Something off?** Run `hypr-doctor --print` for a no-sudo diagnostics report: versions,
  GPU, config errors, the shell's log and more.
- **The login screen comes up black?** Switch to a TTY (`Ctrl`+`Alt`+`F3`) and run
  `sudo rm /etc/sddm.conf.d/10-wayland.conf`. SDDM then falls back to X11 with the same theme.

---

## Keybinds

`SUPER` is the mod key. They all live in
[`modules/binds.lua`](hyprland/.config/hypr/modules/binds.lua), and Menu › Learn › Keybindings
lists them live.

| Keys | Action |
|---|---|
| `SUPER` + `Return` / `E` / `B` | Terminal · file manager · browser |
| `SUPER` + `D` / `V` | App launcher · clipboard history |
| `SUPER` + `SPACE` | The menu |
| `SUPER` + `CTRL` + `O` | The menu, opened on Toggle |
| `SUPER` + `L` / `M` | Lock screen · power menu |
| `SUPER` + `R` | Restart the shell |
| `SUPER` + `SHIFT` + `B` | Bar style: Legacy → Floating → Minimal |
| `SUPER` + `CTRL` + `I` | Caffeine: pause idle lock and suspend |
| `SUPER` + `CTRL` + `SHIFT` + `SPACE` / `SHIFT` + `W` | Theme picker · wallpaper picker |
| `SUPER` + `CTRL` + `SPACE` | Next wallpaper |
| `SUPER` + `SHIFT` + `CTRL` + `A` | Launch the default coding agent |
| `SUPER` + `Q` / `T` / `F` | Close · float · fullscreen |
| `SUPER` + `SHIFT` + `F` / `P` / `J` | Maximize · pseudo-tile · toggle split |
| `SUPER` + arrows | Move focus |
| `SUPER` + drag with left / right mouse button | Move · resize a window |
| `SUPER` + `1`–`0` | Switch workspace (add `SHIFT` to move the window there) |
| `SUPER` + scroll · 3-finger swipe | Cycle workspaces |
| `SUPER` + `S` / `SHIFT` + `S` | Toggle the scratchpad · move a window to it |
| `SUPER` + `Print` / `X` | Screenshot: whole screen · region (saved and copied) |
| `SUPER` + `SHIFT` + `Print` / `X` | Active window · region, clipboard only |

Screenshots go to `~/Pictures/screenshot/`. Volume, brightness and media keys work while locked.
Brightness glides smoothly and never goes below 5%.

---

## Making it yours

### Themes

Every colour lives in one file,
[`themes/<name>/colors.toml`](theme/.config/hypr-theme/themes/). `hypr-theme set <name>` renders
the [templates](theme/.config/hypr-theme/templates/) into `~/.config/hypr-theme/current/` and
tells running apps to reload.

```sh
hypr-theme list            # available themes, * = current
hypr-theme set hyprmono    # apply one
hypr-theme toggle          # dark <-> light
hypr-wall next             # the theme's next wallpaper
```

To make a theme, copy `themes/hyprmono/`, edit `colors.toml`, and drop wallpapers into its
`backgrounds/` folder:

- `mode = "light"` flips GTK, Qt and Neovim to their light variants.
- `hued = true` marks a real palette, so apps get colour where their stock theme has it.

It shows up in the picker straight away. Themes you create are gitignored, so they stay yours.

| Follows a theme switch live | Needs an app restart |
|---|---|
| The shell, Hyprland borders, wallpaper, kitty, Neovim, btop | GTK3 apps (Thunar…), Qt apps |
| GTK4 / libadwaita apps, VS Code, Zen and Electron apps (portal) | Alacritty, Firefox's UI, KDE apps |
| Login screen and `/root` GTK config (root sync) | pkexec apps such as grub-customizer |

A theme can also colour apps the [Aether](https://github.com/omacom/aether) way. See
`nvim_colorscheme = "aether"` and the `*-aether*` templates.

### Bar

Menu › Style › Bar picks the style, the edge and transparency, and has **Widgets** to show or
hide each one. A widget you turn back on returns to its usual place, and *Reset widget order*
restores the default layout. You can also drag empty bar space to another edge.

The layout itself is in `~/.config/hypr-theme/shell.json`, under `bar.layout.<style>`. Its lists
can be edited by hand and apply live. A layout entry that isn't a built-in widget is a
**command module**; any script that prints text (or waybar-style JSON) works:

```json
"modules": { "vpn": { "exec": "~/bin/vpn-status", "interval": 5, "onClick": "nm-connection-editor" } }
```

A module can also be a QML file: `{ "qml": "~/.config/hypr-theme/plugins/mine.qml" }`.

### Dock

Menu › Style › Dock has the settings:

| Mode | |
|---|---|
| Hide when a window covers it (default) | Shown on an empty desktop, slides away while a window would sit under it |
| Auto-hide | Hidden until the cursor touches the screen edge |
| Always visible | Always there, and windows keep clear of it |

It also has the edge, transparency, and **Pinned apps** (tick the ones you want). Click an app to
launch or focus it (click again to cycle its windows), middle-click for a new window, and
right-click to pin, unpin or close.

### Menu, fonts, scale

- **Your own menu entries** go in `~/.config/hypr-theme/menu.local.jsonc`. It is merged into
  [`menu.jsonc`](theme/.config/hypr-theme/menu.jsonc) by id; the format is documented at the top
  of that file.
- **Fonts and size:** `hypr-font set <family>`, `hypr-text-size <px>` and `hypr-scale <n>`
  change the desktop font, the text size everywhere, and the monitor scale. All three are in
  Menu › Style too.
- **Blur, gaps, rounding, animations** are in
  [`decorations.lua`](hyprland/.config/hypr/modules/decorations.lua), reachable from Menu ›
  Style › Edit look & feel.

### The `/hypr` agent skill

If you use a coding agent (Claude Code, Codex, OpenCode, Gemini…), the installer links a
`/hypr` skill into it. Say what you want:

- *"make a warm dark theme called ember"*
- *"add a widget that shows my power draw"*
- *"bind SUPER+N to a scratchpad"*
- *"why is my wifi dropping"*

It reads the rice's own guides, edits the right files, checks the result in both light and dark
with screenshots, and never breaks your session. It won't commit or push anything unless you ask.

---

## Layout

Each top-level folder is a Stow package that mirrors your home directory:

```
hyprland/      ~/.config/hypr/            Lua config: modules/ (binds, monitors, decorations, env, autostart, windowrules), scripts/
quickshell/    ~/.config/quickshell/      the shell: Bar/ Dock/ Launcher/ Menu/ Panels/ Lock/ Power/ Notifications/ Osd/ Picker/ Services/
theme/         ~/.config/hypr-theme/      themes, templates, render engine, menu.jsonc, the /hypr skill; ~/.local/bin/hypr-*
kittyterminal/ alacritty/ nvim/ zsh/ starship/ gtk/      terminals, LazyVim, shell prompt, GTK css
waybar/ rofi/ swaync/ wlogout/            the classic stack, used only if the shell isn't running (HYPR_SHELL=waybar)
sddm/          /usr/share/sddm/themes/hyprmono   login screen (copied by install.sh, not stowed)
```

---

## Credits

Built on [Hyprland](https://hyprland.org/) and the hypr\* ecosystem,
[Quickshell](https://quickshell.org/), [LazyVim](https://www.lazyvim.org/),
[Catppuccin](https://catppuccin.com/), Google's
[Material Symbols](https://fonts.google.com/icons) (Apache 2.0) and
[awww](https://codeberg.org/LGFae/awww). Plenty of ideas come from
[Omarchy](https://omarchy.org/).

**The wallpapers aren't mine and aren't covered by the licence.** HyprMono's mountain is Mount
Ararat over Yerevan (photographer unknown), and *The Creation of Adam* is Michelangelo's (public
domain; this photograph's source is unknown). The others came from wallpaper sites without a
traceable author. If you hold the rights to one, open an issue and it will be credited or removed.

## License

The configuration is [MIT](LICENSE). The bundled wallpapers are excluded; see above.
