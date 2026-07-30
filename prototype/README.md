# Nebula Technical Prototype (Phase 1.0)

Not a theme. Not part of Core. A throwaway probe used once to validate the
real SDDM/Qt6/Wayland environment before writing any Core component — see
[`../docs/Prototype-Results.md`](../docs/Prototype-Results.md) for the
findings and [`../docs/Architecture.md`](../docs/Architecture.md) for
which unknowns this closes.

Deliberately does not use: animations, shaders, Core components, the
`NebulaThemeProvider` system, or the Nord theme. Reads the real SDDM
context properties (`sddm`, `userModel`, `screenModel`, `config`)
directly, the same way `Main.qml` in any installed SDDM theme does (see
`/usr/share/sddm/themes/breeze/Main.qml` for reference).

## Run standalone (no SDDM context)

```bash
qml6 Main.qml
```

Screen resolution comes from the `Screen` attached property; the
SDDM-only fields (screen count, current user) show a placeholder since
`screenModel`/`userModel` don't exist outside a real greeter process.

## Run through SDDM's test mode

```bash
sddm-greeter-qt6 --test-mode --theme "$(pwd)"
```

See `Prototype-Results.md` for the exact result of this command on this
machine, including whether `metadata.desktop` turned out to be required
(it is not listed in the Phase 1.0 brief, but every installed SDDM theme
on this system has one).
