# Nebula

> Modern SDDM framework and theme suite for KDE Plasma 6 and Wayland.

Nebula is not a collection of unrelated SDDM login themes. It is a modular
**framework** — a reusable Core plus a set of themes built on top of it —
for building high-quality, consistent SDDM login screens.

## Status

**0.1 Beta.** The Core is stable, its public API is considered frozen
(see [`docs/API-Stability-Review.md`](docs/API-Stability-Review.md)),
and four official themes ship today: `template` (the reference/starter
theme), `nord`, `glass-dark`, `glass-light`. Every visual building block
— `NebulaThemeConfig`/`NebulaThemeProvider`/`NebulaThemeLoader`,
`NebulaButton`, `NebulaAvatar`, `NebulaClock`, `NebulaDate`,
`NebulaUserList`, `NebulaPasswordField`, `NebulaSessionSelector`,
`NebulaPowerButtons`, `NebulaLoginLayout`, `NebulaBackground`/
`NebulaWallpaper`/`NebulaOverlay`/`NebulaSurface` — is implemented,
documented, and exercised by real themes. A Service/Platform
abstraction (`NebulaAuthService`, `NebulaUserService`,
`NebulaSessionService`, `NebulaPowerService` in `core/services/`,
SDDM-specific adapters in `platform/sddm/`) keeps Core components from
ever calling SDDM directly. A full, real, installable login screen
works today — see
[`docs/Core-Implementation-Status.md`](docs/Core-Implementation-Status.md)
for exactly what's implemented, and [`CHANGELOG.md`](CHANGELOG.md) for
the 0.1 Beta feature summary and known limitations.

## Goals

- KDE Plasma 6, Qt6, SDDM 0.21+
- Wayland first, X11 compatible
- HiDPI and multi-monitor support
- Smooth 60 FPS animations without sacrificing performance or battery life
- Zero QML warnings
- Easy theme customization without touching Core code

## Structure

```text
core/          reusable components, layouts, services, effects, animations, utils, assets
platform/      concrete backend adapters (sddm/) — the only code allowed to call SDDM directly
themes/        official: template, nord, glass-dark, glass-light
               planned: cyberpunk, hacker, amoled, hypr (see docs/Roadmap.md)
docs/          architecture, technical decisions, roadmap, specifications
scripts/       install/uninstall/check-installation/check-theme/check-design-system
tests/         test suite for Core components, plus mocks/ for service adapters
prototype/     throwaway Phase 1.0 SDDM environment probe (not a theme)
.github/       CI workflows and issue/PR templates
```

Themes never redefine what already exists in Core — see
[`docs/Architecture.md`](docs/Architecture.md) for the full rationale.

## Documentation

**Getting started**

| Document                                                      | Content                                          |
| -------------------------------------------------------------- | ------------------------------------------------- |
| [`docs/Installation.md`](docs/Installation.md)                 | How to install, verify, update and uninstall Nebula on a real system |
| [`docs/Creating-A-Theme.md`](docs/Creating-A-Theme.md)          | Step-by-step tutorial: create a new theme from the Template |
| [`docs/Theme-SDK.md`](docs/Theme-SDK.md)                        | Normative contract: what a theme may/must never do, structure, reserved folders |
| [`docs/Core-API.md`](docs/Core-API.md)                          | Public API contract of every Core component            |
| [`docs/API-Stability-Review.md`](docs/API-Stability-Review.md) | Which APIs are frozen, which may still evolve       |
| [`docs/Third-Party-Licenses.md`](docs/Third-Party-Licenses.md) | Licenses for every font, icon and wallpaper used by official themes |

**Architecture & decisions**

| Document                                                      | Content                                          |
| -------------------------------------------------------------- | ------------------------------------------------- |
| [`docs/Architecture.md`](docs/Architecture.md)                 | Problem, users, use cases, target architecture     |
| [`docs/Nebula-Principles.md`](docs/Nebula-Principles.md)       | The project's small set of stable, fundamental rules |
| [`docs/Decisions-Techniques.md`](docs/Decisions-Techniques.md) | Why each major technical choice was made           |
| [`docs/Design-System.md`](docs/Design-System.md)               | Design token catalog (spacing, radius, typography, animation, effects, colors) |
| [`docs/Design-Tokens-Reference.md`](docs/Design-Tokens-Reference.md) | Every token: name, type, default, description, consuming components |
| [`docs/Theme-System.md`](docs/Theme-System.md)                 | End-to-end theming flow: ThemeLoader → ThemeConfig → ThemeProvider → Components |
| [`docs/ThemeLoader.md`](docs/ThemeLoader.md)                   | `NebulaThemeLoader` contract: load cycle, validation strategy |
| [`docs/Services-Architecture.md`](docs/Services-Architecture.md) | How Core components reach SDDM only through Services and Platform Adapters |
| [`docs/Login-Architecture.md`](docs/Login-Architecture.md)     | Interactive login components, full authentication flow |
| [`docs/Rendering-Guidelines.md`](docs/Rendering-Guidelines.md) | Allowed/forbidden QML primitives in Core, plus a performance reference |
| [`docs/Deployment-Decision.md`](docs/Deployment-Decision.md)   | Why the Core installs as a shared QML module         |
| [`docs/Packaging.md`](docs/Packaging.md)                        | Distribution/packaging notes                         |
| [`docs/Specifications-Techniques.md`](docs/Specifications-Techniques.md) | Component contracts and per-theme requirements |

**Validation & compatibility**

| Document                                                      | Content                                          |
| -------------------------------------------------------------- | ------------------------------------------------- |
| [`docs/SDDM-Compatibility.md`](docs/SDDM-Compatibility.md)     | Compatibility matrix with real SDDM/Qt6/Wayland constraints |
| [`docs/Compatibility-Matrix.md`](docs/Compatibility-Matrix.md) | Real, tested differences between `qml6`/`sddm-greeter --test-mode`/real SDDM |
| [`docs/Development-Environment.md`](docs/Development-Environment.md) | Local dev/test setup without touching the active SDDM greeter |
| [`docs/Nord-Validation-Report.md`](docs/Nord-Validation-Report.md) | Nord's validation of the SDK/ThemeLoader mechanism |
| [`docs/Glass-Theme-Report.md`](docs/Glass-Theme-Report.md)     | Glass's validation of the full interactive component set |
| [`docs/Core-Refinement-Review.md`](docs/Core-Refinement-Review.md) | Core consolidation review before the 0.1 Beta freeze |
| [`docs/Prototype-Results.md`](docs/Prototype-Results.md)       | Phase 1.0 real-world test results: SDDM API, multi-screen, HiDPI |
| [`docs/Real-Adapter-Validation.md`](docs/Real-Adapter-Validation.md) | Real end-to-end login round-trip under the real `sddm.service` (Phase 3.2 exit criterion) |

**Project history**

| Document                                                      | Content                                          |
| -------------------------------------------------------------- | ------------------------------------------------- |
| [`docs/Roadmap.md`](docs/Roadmap.md)                            | Phased plan, what's done and what's next          |
| [`docs/Core-Implementation-Status.md`](docs/Core-Implementation-Status.md) | What's actually implemented in `core/`, and why |
| [`docs/Development-Journal.md`](docs/Development-Journal.md)  | Technical discoveries from actually building Nebula (bugs found, causes, fixes) |
| [`docs/Architecture-Review.md`](docs/Architecture-Review.md)   | Phase 0.6 consistency review: what was fixed, risks, Core/Theme boundary |
| [`docs/Core-MVP.md`](docs/Core-MVP.md)                          | Exact scope and exclusions of the Core MVP (Phase 1)     |
| [`docs/Nord-Theme-Specification.md`](docs/Nord-Theme-Specification.md) | Palette, typography, layout for the Nord theme |
| [`docs/Investigations/VK-001-VirtualKeyboard.md`](docs/Investigations/VK-001-VirtualKeyboard.md) | VK-001: oversized virtual keyboard — root cause, fix, real-hardware validation |
| [`CHANGELOG.md`](CHANGELOG.md)                                  | Version history, starting at 0.1 Beta               |
| [`CONTRIBUTING.md`](CONTRIBUTING.md)                            | Coding conventions, commit style, PR process        |
| [`CLAUDE.md`](CLAUDE.md)                                        | Project context for AI-assisted development (FR)   |

## Requirements

- KDE Plasma 6 with **SDDM** 0.21+ as the display/login manager — Nebula
  themes an SDDM greeter specifically, not other login managers
  (`plasmalogin`, GDM, LightDM, ...). Check with
  `systemctl status display-manager.service`.
- Qt 6
- A Wayland or X11 session

## Installation

```bash
sudo scripts/install-nebula.sh nord
```

See [`docs/Installation.md`](docs/Installation.md) for the full
walkthrough (verifying an install, switching the active theme,
uninstalling, updating).

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) before opening a pull request.

## License

GPLv3 — see [`LICENSE`](LICENSE).
