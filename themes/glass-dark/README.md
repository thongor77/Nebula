# Glass Dark

Nebula's second official theme — dark variant. Frosted glass, Fluent
Design inspired: sober translucent surfaces over a soft wallpaper, no
GPU blur (the Core doesn't have one yet, see
[`../../docs/Rendering-Guidelines.md`](../../docs/Rendering-Guidelines.md)).
Built entirely on [`core/`](../../core/) with no modification to it —
first theme to use the full interactive component set from Phase 2.3
(user list, password field, session selector, power buttons) together.
See [`../../docs/Glass-Theme-Report.md`](../../docs/Glass-Theme-Report.md)
for the full validation report, design rationale, and known
limitations.

## Identity

Inspirations: Windows 11/Fluent Design, modern KDE Breeze, macOS
Sonoma (for depth) — sober, no saturated colors, no artificial
reflections, no permanent animation. The "glass" feel comes entirely
from `NebulaSurface`'s opacity/radius/shadow tokens plus a soft
wallpaper showing through, not a shader effect.

`glass-light` (see [`../glass-light/`](../glass-light/)) shares every
token name with this theme — only the values differ. Both are fully
independent SDK-compliant themes (own `Main.qml`/`theme.conf`/
`metadata.desktop`), not a single theme with a mode switch.

Typography: Noto Sans — tested against Inter and Cantarell (see
`Glass-Theme-Report.md` for the justification). Surfaces:
`surfaceOpacity=0.75`, `radiusLarge=20`, shadow opacity 0.3/offset 4 —
chosen after comparing 4 opacity/radius/shadow combinations side by
side (see `Glass-Theme-Report.md`).

## Assets

- `assets/wallpapers/glass-dark.png` (3840×2160) +
  `glass-dark-compressed.jpg` — an original, low-saturation dark
  gradient generated for this project (ImageMagick). No external
  dependency, freely redistributable under this repository's license
  (GPLv3).
- `assets/icons/{shutdown,restart,suspend,hibernate,reveal-password}.png`
  (64×64, transparent, `#8E8E93` gray) — a consistent original icon set.
  **Not currently wired into the real UI**: neither `NebulaPowerButtons`
  nor `NebulaPasswordField` expose an icon property yet — a real, known
  Core limitation, documented rather than fixed (see
  `Glass-Theme-Report.md`, Constat #1). The icons are ready for when
  that Core evolution happens.
- `assets/fonts/` — empty: Noto Sans is expected to already be
  installed on the system (see Typography above).

## Known limitations (this phase)

See [`../../docs/Glass-Theme-Report.md`](../../docs/Glass-Theme-Report.md)
for the full list — most notably the icon-customization gap above, and
a deployment-architecture discovery (not specific to Glass) fixed in
`scripts/install-nebula.sh` (see DT-0023 in
[`../../docs/Decisions-Techniques.md`](../../docs/Decisions-Techniques.md)).

## Options

`theme.conf` overrides 17 tokens: 9 colors, 2 radii, 3 opacity/border
values, 1 animation duration, 2 font families. See `theme.conf` itself
for the exact values and inline rationale.
