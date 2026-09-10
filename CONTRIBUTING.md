# Contributing to Nebula

Nebula is at **0.1 Beta** — the Core is implemented and its public API is
frozen (see [`docs/API-Stability-Review.md`](docs/API-Stability-Review.md)),
four official themes ship, and real SDDM integration is validated on real
hardware (see [`CHANGELOG.md`](CHANGELOG.md)). Before writing code, read:

- Building a theme: [`docs/Theme-SDK.md`](docs/Theme-SDK.md) →
  [`docs/Creating-A-Theme.md`](docs/Creating-A-Theme.md) →
  [`docs/Core-API.md`](docs/Core-API.md).
- Working on the Core: [`docs/Architecture.md`](docs/Architecture.md) →
  [`docs/Decisions-Techniques.md`](docs/Decisions-Techniques.md) →
  [`docs/Specifications-Techniques.md`](docs/Specifications-Techniques.md) →
  [`docs/Core-API.md`](docs/Core-API.md) →
  [`docs/API-Stability-Review.md`](docs/API-Stability-Review.md) (public
  API is frozen — see DT-0003 and the freeze criteria there before
  proposing a change to an existing component).
- Either way: [`docs/Development-Environment.md`](docs/Development-Environment.md)
  (testing without touching your system's active SDDM greeter) and
  [`docs/Roadmap.md`](docs/Roadmap.md) (what's planned, so you don't
  duplicate work already in flight).

The most useful contribution right now is exercising the Core with a
theme that pushes it somewhere Nord/Glass didn't (see
[`docs/Dashboard-Architecture-Stress-Test.md`](docs/Dashboard-Architecture-Stress-Test.md)
for what that kind of exercise looks like) — real usage is how a genuine
API gap gets found, rather than proposed speculatively.

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
  and compatibility notes — see `themes/nord/README.md` or
  `themes/glass-dark/README.md` for the expected shape.

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
