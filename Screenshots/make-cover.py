#!/usr/bin/env python3
"""Screenshots/cover.png, the README cover: the wordmark with orbits, the
tagline and the four shipped themes' real previews (themes/<id>/preview.jpg,
from orrery-theme-preview). Rerun after retaking a preview:
    python3 Screenshots/make-cover.py        (needs rsvg-convert, Inter, JetBrains Mono)"""
import math, os, random, shutil, subprocess, tempfile

OUT = os.path.dirname(os.path.abspath(__file__))
THEMES = os.path.join(OUT, "..", "theme", ".config", "orrery", "themes")
HERE = tempfile.mkdtemp()      # the SVG and the copies it links to
W, H = 2400, 1110
BG, BG2 = "#09090c", "#14141a"
FG, MUTED, FAINT = "#ededf0", "#9a9aa4", "#2a2a33"

# (id, label, planet colour, planet radius, orbit index, angle on orbit in deg)
SHOTS = [
    ("eclipse",          "Eclipse",          "#e8e8e8", 9,  0, 200),
    ("zenith",           "Zenith",           "#f4f4f4", 13, 1, 332),
    ("catppuccin-mocha", "Catppuccin Mocha", "#b4befe", 11, 1, 158),
    ("cassini",          "Cassini",          "#9fd8ce", 15, 2, 18),
]

cx, cy = W / 2, 330            # centre of the system (the wordmark)
TILT = -9
ORBITS = [(560, 118, 0.30), (820, 178, 0.20), (1080, 238, 0.12)]   # rx, ry, opacity

def on_orbit(i, deg):
    rx, ry, _ = ORBITS[i]
    t = math.radians(deg)
    x, y = rx * math.cos(t), ry * math.sin(t)
    a = math.radians(TILT)
    return cx + x * math.cos(a) - y * math.sin(a), cy + x * math.sin(a) + y * math.cos(a)

out = []
add = out.append
add(f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
    f'width="{W}" height="{H}" viewBox="0 0 {W} {H}">')
add(f'''<defs>
  <radialGradient id="glow" cx="50%" cy="28%" r="60%">
    <stop offset="0" stop-color="{BG2}"/><stop offset="1" stop-color="{BG}"/>
  </radialGradient>
  <radialGradient id="sun" cx="50%" cy="50%" r="50%">
    <stop offset="0" stop-color="#ffffff" stop-opacity="0.10"/>
    <stop offset="1" stop-color="#ffffff" stop-opacity="0"/>
  </radialGradient>
  <filter id="soft" x="-200%" y="-200%" width="500%" height="500%">
    <feGaussianBlur stdDeviation="7"/>
  </filter>
  <filter id="feather"><feGaussianBlur stdDeviation="14"/></filter>
  <mask id="quiet" maskUnits="userSpaceOnUse" x="0" y="0" width="{W}" height="{H}">
    <rect width="{W}" height="{H}" fill="#fff"/>
    <rect x="{cx - 720}" y="{cy + 100}" width="1440" height="76" rx="38" fill="#000" filter="url(#feather)"/>
  </mask>
  <clipPath id="card"><rect width="{W}" height="{H}" rx="32"/></clipPath>
</defs>''')
add('<g clip-path="url(#card)">')
add(f'<rect width="{W}" height="{H}" fill="url(#glow)"/>')

# stars: fixed seed, faint, fewer near the wordmark
rnd = random.Random(7)
for _ in range(230):
    x, y = rnd.uniform(0, W), rnd.uniform(0, H * 0.58)
    if abs(x - cx) < 560 and abs(y - cy) < 110:
        continue
    r = rnd.choice([0.8, 0.8, 1.0, 1.2, 1.6])
    add(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r}" fill="#ffffff" opacity="{rnd.uniform(0.12, 0.5):.2f}"/>')

# a soft light where the sun would be, then the orbits
add(f'<ellipse cx="{cx}" cy="{cy}" rx="700" ry="260" fill="url(#sun)"/>')
add('<g mask="url(#quiet)">')
for rx, ry, op in ORBITS:
    add(f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="none" stroke="#ffffff" '
        f'stroke-opacity="{op}" stroke-width="1.6" transform="rotate({TILT} {cx} {cy})"/>')

add('</g>')
# the wordmark
add(f'<text x="{cx}" y="{cy + 64}" text-anchor="middle" font-family="Inter Display" font-weight="200" '
    f'font-size="184" letter-spacing="58" fill="{FG}">ORRERY</text>')
add(f'<text x="{cx}" y="{cy + 150}" text-anchor="middle" font-family="Inter" font-weight="300" '
    f'font-size="40" letter-spacing="1.5" fill="{MUTED}">a Hyprland desktop where everything orbits one palette</text>')

# planets: one per theme, drawn over the orbits and the text
for tid, label, col, r, oi, deg in SHOTS:
    x, y = on_orbit(oi, deg)
    add(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r * 1.8}" fill="{col}" opacity="0.35" filter="url(#soft)"/>')
    add(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r}" fill="{col}"/>')
    if tid == "cassini":   # a ringed giant gets its ring
        add(f'<ellipse cx="{x:.1f}" cy="{y:.1f}" rx="{r * 2.1}" ry="{r * 0.55}" fill="none" '
            f'stroke="{col}" stroke-opacity="0.8" stroke-width="2" transform="rotate(-18 {x:.1f} {y:.1f})"/>')

# the four real previews
M, GAP = 110, 36
pw = (W - 2 * M - 3 * GAP) / 4
ph = pw * 900 / 1600
py = 650
for i, (tid, label, col, r, oi, deg) in enumerate(SHOTS):
    shutil.copy(f"{THEMES}/{tid}/preview.jpg", f"{HERE}/{tid}.jpg")
    px = M + i * (pw + GAP)
    add(f'<clipPath id="c{i}"><rect x="{px:.1f}" y="{py}" width="{pw:.1f}" height="{ph:.1f}" rx="14"/></clipPath>')
    add(f'<rect x="{px - 1:.1f}" y="{py - 1}" width="{pw + 2:.1f}" height="{ph + 2:.1f}" rx="15" fill="#000" opacity="0.6" filter="url(#soft)"/>')
    add(f'<image x="{px:.1f}" y="{py}" width="{pw:.1f}" height="{ph:.1f}" xlink:href="{tid}.jpg" '
        f'preserveAspectRatio="xMidYMid slice" clip-path="url(#c{i})"/>')
    add(f'<rect x="{px:.1f}" y="{py}" width="{pw:.1f}" height="{ph:.1f}" rx="14" fill="none" stroke="#ffffff" stroke-opacity="0.14" stroke-width="1.5"/>')
    ly = py + ph + 62
    tw = len(label) * 15.2 + (len(label) - 1) * 4.2     # rough text width, for the dot
    lx = px + pw / 2
    add(f'<circle cx="{lx - tw / 2 - 22:.1f}" cy="{ly - 9}" r="7" fill="{col}"/>')
    add(f'<text x="{lx:.1f}" y="{ly}" text-anchor="middle" font-family="JetBrainsMono Nerd Font" font-weight="400" '
        f'font-size="25" letter-spacing="4" fill="{MUTED}">{label.upper()}</text>')

add('</g></svg>')
with open(f"{HERE}/cover.svg", "w") as fh:
    fh.write("\n".join(out))
subprocess.run(["rsvg-convert", "-w", "2000", "-o", f"{OUT}/cover.png", f"{HERE}/cover.svg"], check=True)
shutil.rmtree(HERE)
print(f"{OUT}/cover.png")
