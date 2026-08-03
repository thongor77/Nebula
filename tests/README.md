# Tests

Test suite for Core components (`core/`). Introduced during the
architecture review to close a real gap: no testing strategy existed
before.

Each Core component's Definition of Done requires a minimal test in this
directory — see
[`docs/Specifications-Techniques.md`](../docs/Specifications-Techniques.md).

| File                       | Purpose                                                    |
| --------------------------- | ------------------------------------------------------------ |
| `ButtonHarness.qml`         | `NebulaButton` in isolation (variants, states)              |
| `LoginScreenHarness.qml`    | Full layered static login screen (no SDDM, no theme)        |
| `LoginWorkflowHarness.qml`  | Full interactive login flow via Mock adapters                |
| `ServicesHarness.qml`       | The 4 Core Services in isolation, via Mock adapters          |
| `ThemeHarness.qml`          | Loads and visualizes a real theme's tokens standalone        |
| `ThemeInspector.qml`        | Per-token origin (theme value vs. Core default)              |
| `ThemeLoaderHarness.qml`    | The 5 required `NebulaThemeLoader` scenarios                 |
| `ThemeSyncCheck.qml`        | Automated: fails if `ThemeConfig`/`ThemeProvider` token groups diverge |
| `VisualHarness.qml`         | Every component on one page — visual regression reference    |
| `mocks/`                    | Mock Platform Adapters (no real SDDM needed)                  |
| `fixtures/`                 | Shared test data                                              |

The concrete automated test framework (QML `TestCase` via `QtTest`, or
another approach) is still not chosen — every harness above except
`ThemeSyncCheck.qml` is a manual **visual** harness, not an automated
test: run it with `qml6 tests/<Harness>.qml` and inspect the result (see
[`docs/Core-Implementation-Status.md`](../docs/Core-Implementation-Status.md)
for what was verified this way). They should be replaced or complemented
by real automated tests once the framework decision is made.
