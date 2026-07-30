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

| Theme       | Identity (planned)                                   |
| ----------- | ----------------------------------------------------- |
| `cyberpunk` | Neon, high contrast, glitch accents                   |
| `hacker`    | Terminal green-on-black, monospace, minimal chrome    |
| `amoled`    | Pure black, battery/OLED friendly, high contrast       |
| `nord`      | Nord color palette, calm and understated               |
| `glass`     | Frosted glass / acrylic blur, translucent surfaces      |
| `hypr`      | Aesthetic aligned with the Hyprland/wlroots community  |

No theme is implemented yet — this comes after the Core architecture is
validated (see [`docs/Roadmap.md`](../docs/Roadmap.md)).
