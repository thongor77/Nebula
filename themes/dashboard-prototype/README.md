# Dashboard (Prototype)

**Not a production theme.** This is the executable artifact of the
Dashboard Architecture Stress Test — see
[`../../docs/Dashboard-Architecture-Stress-Test.md`](../../docs/Dashboard-Architecture-Stress-Test.md)
for the full written analysis this prototype validates. Not on the
Roadmap as a future official theme (unlike `amoled`/`cyberpunk`/
`hacker`/`hypr`, which are placeholders for planned themes).

## What it proves, by actually running

- A left (system status) + center (identity/auth) + right (session/
  input) composition is reachable **without any Core change**, by
  bypassing `NebulaLoginLayout` and composing `NebulaBackground` +
  `NebulaSurface` + the interactive components directly — every
  component still used strictly through its documented public API.
- Theme-specific toggles (`showLeftPanel`/`showRightPanel` in
  `Main.qml`) work as plain QML properties, without any `theme.conf` or
  `NebulaThemeLoader` change.
- Responsive fallback: below `1100px` wide, side panels hide and the
  screen reduces to "authentication first" (center card + power
  actions only) — the brief's own suggested small-screen strategy.

## What is intentionally mocked

Left panel's Host/Battery/Network cards and the right panel's keyboard
layout label are **static placeholder text**, not backed by any Core
Service — there is no `NebulaSystemInfoService` and no implemented
`NebulaKeyboardSelector` today (see the analysis doc, Gap 3, and
`Core-API.md`'s `NebulaKeyboardSelector` entry). Everything else in this
theme (auth, user/session selection, power actions, the virtual keyboard
toggle) is wired to real Core Services/Adapters, identically to
`template`/`nord`/`glass-dark`/`glass-light`.

## Structure

Same SDK contract as any other theme (`docs/Theme-SDK.md`):
`README.md`, `metadata.desktop`, `theme.conf`, `Main.qml`,
`preview.png`, `assets/{wallpapers,icons,fonts}/` (all empty — no
wallpaper image shipped, falls back to the flat `backgroundColor`, same
convention as `themes/template`).
