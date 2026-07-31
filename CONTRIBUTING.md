# Contributing to Nebula

Nebula is currently in its **architecture phase** — no QML implementation
exists yet. Before writing code, read:

1. [`README.md`](README.md)
2. [`docs/Architecture.md`](docs/Architecture.md)
3. [`docs/Decisions-Techniques.md`](docs/Decisions-Techniques.md)
4. [`docs/Design-System.md`](docs/Design-System.md)
5. [`docs/Theme-System.md`](docs/Theme-System.md)
6. [`docs/Specifications-Techniques.md`](docs/Specifications-Techniques.md)
7. [`docs/Core-API.md`](docs/Core-API.md)
8. [`docs/SDDM-Compatibility.md`](docs/SDDM-Compatibility.md)
9. [`docs/Development-Environment.md`](docs/Development-Environment.md)
10. [`docs/Theme-SDK.md`](docs/Theme-SDK.md) and
    [`docs/Creating-A-Theme.md`](docs/Creating-A-Theme.md) (if you are
    creating a theme rather than a Core component)
11. [`docs/Roadmap.md`](docs/Roadmap.md)

If you want to help before implementation starts, the most useful
contribution is feedback on the architecture and specifications above, not
code.

---

## Core principle

Nebula is a framework, not a collection of independent themes. Before
adding anything to a theme, ask: *does this belong in `core/` instead?*
Duplicating a component across themes is treated as a bug — see
`docs/Architecture.md`.

## Coding style

- Small QML files, single responsibility per file.
- Clear, descriptive property names — no abbreviations that aren't obvious.
- Consistent formatting (4-space indentation, one component per file).
- No magic numbers — use named tokens exposed through
  `NebulaThemeProvider` instead (see `docs/Design-System.md`), never read
  `ThemeConfig`/`ThemeLoader` directly.
- Keep JavaScript minimal inside QML; business logic belongs in
  `core/utils/` helper files, not inline in components.
- Document the *why*, not the *what* — a comment should explain a
  non-obvious constraint or workaround, not restate the code.

## Naming convention

Every component exported by Core is prefixed `Nebula`:
`NebulaButton`, `NebulaClock`, `NebulaThemeConfig`, `NebulaThemeProvider`,
etc. See [`docs/Core-API.md`](docs/Core-API.md) for the full component
list and public API contract.

## Performance rules

- Avoid unnecessary property bindings.
- Avoid expensive timers — a clock updates at most once per second.
- Avoid nested `Repeater`s.
- Lazy-load whenever possible.
- Cache resources (images, fonts) instead of reloading them.
- Never block the UI thread — this is a login screen, it must always
  stay responsive.

## Documentation

- Every exported component must have a short top-of-file description.
- Every public property must include a one-line description of its
  purpose.
- Theme `README.md` files should explain identity, customization options,
  and compatibility notes once the theme exists.

## Commit messages

Imperative present tense, English, one clear intention per commit:

```text
Add NebulaClock component
Fix focus state on NebulaPasswordField
Refactor ThemeLoader error handling
```

Avoid:

```text
fixed bug
WIP
feat: add feature
```

Don't mix a fix and a new feature in the same commit.

## Pull requests

- One logical feature or fix per PR.
- Include screenshots for any visual change.
- Explain the architectural reasoning behind non-trivial choices, and
  link to the relevant section of `docs/` if applicable.
- If your change affects the Core/Theme contract, update
  `docs/Specifications-Techniques.md` **and** `docs/Core-API.md` in the
  same PR (see DT-0009).
- Before any new feature: check whether it belongs to Core or to a theme,
  document its API before implementing it, and avoid any dependency on a
  specific theme (see `CLAUDE.md`).

## Definition of Done for a Core component

See the checklist in
[`docs/Specifications-Techniques.md`](docs/Specifications-Techniques.md#4-definition-of-done--composant-core):
zero QML warnings, all visual values sourced exclusively from
`NebulaThemeProvider` (never `ThemeConfig`/`ThemeLoader` directly), every
public property documented, keyboard focus handled for interactive
components, consistent behavior across Wayland and X11 (or the
difference is documented and intentional).
