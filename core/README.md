# Core

Reusable building blocks shared by every Nebula theme.

Themes never redefine what already exists here — see [`docs/Architecture.md`](../docs/Architecture.md).

| Directory     | Purpose                                                        |
| ------------- | --------------------------------------------------------------|
| `components/` | Visual QML components (Clock, UserList, PasswordField, ...)   |
| `effects/`    | Shader / GPU effects (blur, glow, particles)                  |
| `animations/` | Reusable animation definitions and the AnimationManager        |
| `utils/`      | Non-visual JS/QML helpers (ThemeLoader, ThemeConfig, ...)      |
| `assets/`     | Shared fonts and icons used across themes                      |

No implementation yet — component list and contracts are being defined in
[`docs/Specifications-Techniques.md`](../docs/Specifications-Techniques.md).
