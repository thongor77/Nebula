# Nord

Nebula's first official theme — calm, understated, built entirely on
[`core/`](../../core/) with no modification to it. Validates the Theme
SDK (see [`../../docs/Theme-SDK.md`](../../docs/Theme-SDK.md)) and
`NebulaThemeLoader` (see
[`../../docs/ThemeLoader.md`](../../docs/ThemeLoader.md)) end to end.

## Identity

Palette: the official [Nord](https://www.nordtheme.com/) color scheme
(MIT-licensed specification) — only the published color values are used,
mapped to Nebula's Design Tokens. No code or image asset from the Nord
project is reused. See
[`../../docs/Nord-Theme-Specification.md`](../../docs/Nord-Theme-Specification.md)
for the full token mapping and design rationale.

Typography, spacing, radius and animation intentionally stay at the
Core's own neutral defaults — Nord's identity here is expressed purely
through color, not a different scale.

## Assets

- `assets/wallpapers/nord-gradient.png` — a plain vertical gradient
  between two Nord palette colors (`#2E3440` → `#3B4252`), generated
  programmatically for this project (ImageMagick). No external
  dependency, no license concern, freely redistributable under the same
  license as this repository (GPLv3).
- `assets/icons/`, `assets/fonts/` — empty: no custom icon or font is
  needed yet (`NebulaAvatar`'s built-in zero-asset fallback silhouette
  covers the current scope, see
  [`../../docs/Core-API.md`](../../docs/Core-API.md)).

## Known limitations (this phase)

Nord is deliberately built with only the Core components that exist
today. There is no real username input, password field, session
selector, or power actions yet — see
[`../../docs/Nord-Validation-Report.md`](../../docs/Nord-Validation-Report.md)
for the full list and why this isn't a failure of this phase.

## Options

None yet — `theme.conf` only overrides the 9 color tokens listed in
`Nord-Theme-Specification.md` §2.
