# Themes

Each subdirectory is a theme identity built entirely on top of [`core/`](../core/).

A theme only defines:

- colors
- wallpapers
- animations (parameters, not engines)
- layout
- theme-specific assets

If a theme needs a new visual behavior, it belongs in `core/` first, then
gets configured per-theme. Duplicating a Core component inside a theme is
considered a bug — see [`docs/Architecture.md`](../docs/Architecture.md).

| Theme       | Identity                                              | Status |
| ----------- | ----------------------------------------------------- | ------ |
| `nord`      | Nord color palette, calm and understated               | Implemented (Phase 2.1) — see [`../docs/Nord-Validation-Report.md`](../docs/Nord-Validation-Report.md) |
| `cyberpunk` | Neon, high contrast, glitch accents                   | Planned |
| `hacker`    | Terminal green-on-black, monospace, minimal chrome    | Planned |
| `amoled`    | Pure black, battery/OLED friendly, high contrast       | Planned |
| `glass`     | Frosted glass / acrylic blur, translucent surfaces      | Planned |
| `hypr`      | Aesthetic aligned with the Hyprland/wlroots community  | Planned |

`nord` is the first visual theme implemented (see
[`docs/Roadmap.md`](../docs/Roadmap.md), Phase 2.1) — built with only the
Core components that exist today, deliberately incomplete functionally
(no password field/user list yet). The others come later.
[`template/`](template/) is not one of them: it's the neutral base every
theme above copies from — see
[`../docs/Creating-A-Theme.md`](../docs/Creating-A-Theme.md).
