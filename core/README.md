# Core

Reusable building blocks shared by every Nebula theme.

Themes never redefine what already exists here — see [`docs/Architecture.md`](../docs/Architecture.md).

| Directory     | Purpose                                                        |
| ------------- | --------------------------------------------------------------|
| `components/` | Visual QML components (`NebulaButton`, `NebulaAvatar`, `NebulaClock`, `NebulaDate`, `NebulaUserList`, `NebulaPasswordField`, `NebulaSessionSelector`, `NebulaPowerButtons`, `NebulaBackground`/`NebulaWallpaper`/`NebulaOverlay`/`NebulaSurface`, `NebulaVirtualKeyboard`/`NebulaInputPanel`) |
| `layouts/`    | `NebulaLoginLayout` — the four-zone login screen skeleton      |
| `services/`   | `NebulaAuthService`, `NebulaUserService`, `NebulaSessionService`, `NebulaPowerService` — public contract, delegate to an injected Platform Adapter |
| `config/`     | `NebulaThemeConfig` — resolved design token values             |
| `theme/`      | `NebulaThemeProvider`, `NebulaThemeLoader`                     |
| `effects/`    | Shader / GPU effects (blur, glow, particles) — planned, not yet implemented (Phase 3) |
| `animations/` | Reusable animation definitions and the AnimationManager — planned, not yet implemented (Phase 3) |
| `utils/`      | Non-visual JS/QML helpers — currently unused                   |
| `assets/`     | Shared fonts and icons used across themes — currently unused   |

The Core is implemented and its public API is frozen as of Milestone 0.1
Beta — see [`docs/Core-API.md`](../docs/Core-API.md) for the contract of
every component and [`docs/Core-Implementation-Status.md`](../docs/Core-Implementation-Status.md)
for exactly what's built and the decisions made along the way.
