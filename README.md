# Nebula

> Modern SDDM framework and theme suite for KDE Plasma 6 and Wayland.

Nebula is not a collection of unrelated SDDM login themes. It is a modular
**framework** — a reusable Core plus a set of themes built on top of it —
for building high-quality, consistent SDDM login screens.

## Status

**Core MVP in progress.** The architecture, contracts and a real technical
prototype are done (see [`docs/Roadmap.md`](docs/Roadmap.md), Phases 0 to
1.0). Phases 1.1-1.3 landed the first real Core components —
`NebulaThemeConfig`, `NebulaThemeProvider`, `NebulaButton`, `NebulaAvatar`,
`NebulaClock`, `NebulaDate` — plus `NebulaLoginLayout`, the shared
four-zone skeleton every theme's login screen will build on. Each piece
is tested and visually verified. A static login screen (avatar + clock +
date + button, no theme) already works on top of Core alone, built
through the layout — see
[`docs/Core-Implementation-Status.md`](docs/Core-Implementation-Status.md).
No theme exists yet.

## Goals

- KDE Plasma 6, Qt6, SDDM 0.21+
- Wayland first, X11 compatible
- HiDPI and multi-monitor support
- Smooth 60 FPS animations without sacrificing performance or battery life
- Zero QML warnings
- Easy theme customization without touching Core code

## Structure

```text
core/          reusable components, effects, animations, utils, assets
themes/        theme identities (cyberpunk, hacker, amoled, nord, glass, hypr)
docs/          architecture, technical decisions, roadmap, specifications
scripts/       packaging and tooling scripts
tests/         test suite for Core components
prototype/     throwaway Phase 1.0 SDDM environment probe (not a theme)
.github/       CI workflows and issue/PR templates
```

Themes never redefine what already exists in Core — see
[`docs/Architecture.md`](docs/Architecture.md) for the full rationale.

## Documentation

| Document                                                      | Content                                          |
| -------------------------------------------------------------- | ------------------------------------------------- |
| [`docs/Architecture.md`](docs/Architecture.md)                 | Problem, users, use cases, target architecture     |
| [`docs/Decisions-Techniques.md`](docs/Decisions-Techniques.md) | Why each major technical choice was made           |
| [`docs/Roadmap.md`](docs/Roadmap.md)                            | Phased plan from architecture to first theme       |
| [`docs/Specifications-Techniques.md`](docs/Specifications-Techniques.md) | Component contracts and per-theme requirements |
| [`docs/Design-System.md`](docs/Design-System.md)               | Design token catalog (spacing, radius, typography, animation, effects, colors) |
| [`docs/Theme-System.md`](docs/Theme-System.md)                 | End-to-end theming flow: ThemeLoader → ThemeConfig → ThemeProvider → Components |
| [`docs/Core-API.md`](docs/Core-API.md)                          | Public API contract of every Core component            |
| [`docs/SDDM-Compatibility.md`](docs/SDDM-Compatibility.md)     | Compatibility matrix with real SDDM/Qt6/Wayland constraints |
| [`docs/Development-Environment.md`](docs/Development-Environment.md) | Local dev/test setup without touching the active SDDM greeter |
| [`docs/Theme-Development.md`](docs/Theme-Development.md)       | How to create a new theme on top of Core                |
| [`docs/Architecture-Review.md`](docs/Architecture-Review.md)   | Phase 0.6 consistency review: what was fixed, risks, Core/Theme boundary |
| [`docs/Core-MVP.md`](docs/Core-MVP.md)                          | Exact scope and exclusions of the Core MVP (Phase 1)     |
| [`docs/Nord-Theme-Specification.md`](docs/Nord-Theme-Specification.md) | Palette, typography, layout for the pilot theme (Nord) |
| [`docs/Prototype-Results.md`](docs/Prototype-Results.md)       | Phase 1.0 real-world test results: SDDM API, multi-screen, HiDPI |
| [`docs/Core-Implementation-Status.md`](docs/Core-Implementation-Status.md) | What's actually implemented in `core/`, and why |
| [`docs/Development-Journal.md`](docs/Development-Journal.md)  | Technical discoveries from actually building Nebula (bugs found, causes, fixes) |
| [`CONTRIBUTING.md`](CONTRIBUTING.md)                            | Coding conventions, commit style, PR process        |
| [`CLAUDE.md`](CLAUDE.md)                                        | Project context for AI-assisted development (FR)   |

## Requirements (planned)

- KDE Plasma 6 with SDDM 0.21+
- Qt 6
- A Wayland or X11 session

Installation instructions will be added once a first theme ships.

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) before opening a pull request.

## License

GPLv3 — see [`LICENSE`](LICENSE).
