# Changelog — Nebula

Format inspired by [Keep a Changelog](https://keepachangelog.com/).
Versions before 0.1 Beta were internal development phases, not
releases — see [`docs/Roadmap.md`](docs/Roadmap.md) for that full
history rather than repeating it here.

## [0.1.0-beta] — 2026-09-10

First public release. The question this release answers is not "does
Nebula work?" but "can someone outside the project actually use it?" —
every item below was validated on real hardware (a genuinely separate
clean machine for installation, this project's own 3-monitor mixed-DPI
rig for rendering, a real `sddm.service` for authentication), not just
reasoned about or run under `--test-mode` alone.

### Added

**Core architecture** — stable and documented, public API frozen as of
this release (see
[`docs/API-Stability-Review.md`](docs/API-Stability-Review.md) for the
exact Stable/Frozen vs. Limited vs. Experimental breakdown):
`NebulaThemeConfig`/`NebulaThemeProvider`/`NebulaThemeLoader`,
`NebulaButton`, `NebulaAvatar`, `NebulaClock`, `NebulaDate`,
`NebulaUserList`, `NebulaPasswordField`, `NebulaSessionSelector`,
`NebulaPowerButtons`, `NebulaLoginLayout`, `NebulaBackground`/
`NebulaWallpaper`/`NebulaOverlay`/`NebulaSurface`,
`NebulaVirtualKeyboard` (+ internal `NebulaInputPanel`). Icon support
(`icon`/`iconSize` and friends, all optional) and localizable labels
(previously hardcoded strings like "Show"/"Hide") added across the
interactive components.

**Real SDDM adapters** (`platform/sddm/`) — `SDDMAuthAdapter`,
`SDDMUserAdapter`, `SDDMSessionAdapter`, `SDDMPowerAdapter` behind the
`NebulaAuthService`/`NebulaUserService`/`NebulaSessionService`/
`NebulaPowerService` abstraction (Core components never call SDDM
directly). No longer skeletons: the full authentication round-trip —
password field → `NebulaAuthService` → `SDDMAuthAdapter` →
`sddm.login()` → real PAM → a real Plasma session starting — was
validated end-to-end under the real `sddm.service`, journal-confirmed
(see [`docs/Real-Adapter-Validation.md`](docs/Real-Adapter-Validation.md)).
User/session listing and power actions (shutdown/reboot/suspend/
hibernate) are equally real, backed by SDDM's actual `userModel`/
`sessionModel`/`sddm` context properties.

**Theme SDK** — `themes/template/` + `docs/Theme-SDK.md` (normative
contract) + `docs/Creating-A-Theme.md` (tutorial) + `docs/Core-API.md`
(component contracts) + `docs/Design-Tokens-Reference.md` (every
token) — validated by actually building a theme from documentation
alone, without consulting `core/` source. `themes/template/Main.qml`
additionally annotates which wiring is mandatory vs. optional (virtual
keyboard, session selector, power actions) for a theme author starting
from it.

**Four official themes**, each independently installable with no Core
modification: `template` (starter/reference, not meant to be used
as-is), `nord` (the official Nord palette), `glass-dark`/`glass-light`
(frosted-glass, sharing every token name across the light/dark
variant). An internal `themes/dashboard-prototype` also exists —
**not an official theme**: a deliberately non-production architecture
stress-test artifact validating that a radically different,
multi-panel layout is reachable without any Core change (see its own
`README.md` and
[`docs/Dashboard-Architecture-Stress-Test.md`](docs/Dashboard-Architecture-Stress-Test.md)).

**Installation system**: `scripts/install-nebula.sh`/
`uninstall-nebula.sh`/`check-installation.sh`/`check-theme.sh`/
`check-design-system.sh`, sharing common detection logic via
`scripts/lib/common.sh` — idempotent, tested on genuinely clean
machines (fresh install, multi-theme coexistence, selective/full
uninstall, bad-input handling, re-run idempotency).

**Validation & harnesses**: ten `tests/*.qml` harnesses (component,
service, login-workflow, theme-loading) exercising the Core with mock
adapters, zero SDDM dependency. `MockAuthAdapter` now exercises the
same `sessionIndex` parameter the real adapter uses, closing a real
test blind spot. A dedicated
[`docs/Beta-Release-Checklist.md`](docs/Beta-Release-Checklist.md)
defines the repeatable release-quality gates used for this release
(lint, structural checks, install round-trip, real multi-screen
validation).

**Multi-monitor / HiDPI validation**: every official theme rendered
correctly under real `sddm-greeter-qt6 --test-mode` on this project's
3 physical monitors at mixed scale factors (100/125/150/200%), one
`QQuickView` per screen as SDDM itself does it — not simulated.
`NebulaVirtualKeyboard` specifically fixes a real bug in this area
(VK-001: an on-screen keyboard rendered at a fixed, oversized size on
mixed-DPI setups because no Core component hosted a real
`QtQuick.VirtualKeyboard.InputPanel` — see
[`docs/Investigations/VK-001-VirtualKeyboard.md`](docs/Investigations/VK-001-VirtualKeyboard.md)),
itself re-validated under the real `sddm.service` across all 3 screens
on every theme it's wired into (`template`, `glass-dark`,
`glass-light`; `nord` is out of scope, no real password field).

**Licensing**: [`docs/Third-Party-Licenses.md`](docs/Third-Party-Licenses.md)
— every bundled asset (icons, wallpapers) is an original creation for
this project (GPLv3); the only external dependency (Noto Sans, used by
Glass) is a system font under SIL OFL 1.1, never bundled.

### Fixed

- **Real accessibility bug**: `KeyNavigation.tab` targeting
  `NebulaPasswordField` left keyboard focus on the outer `Rectangle`
  instead of the internal `TextInput` — fixed in the Core, every theme
  benefits automatically.
- **Real race condition** (found validating VK-001 on real hardware):
  `NebulaVirtualKeyboard.keyboardActive` depended on Qt's own async
  `InputMethod.visible` rather than the component's own synchronous
  `state`, intermittently leaving the keyboard panel overlapping the
  login form instead of making room for it. Fixed by deriving
  `keyboardActive` from `state` directly.
- **Real layout bug in `NebulaLoginLayout`** (found the same session):
  `mainArea` only compensated by half of `bottomInset` while
  `footerArea` compensated the full amount — on screens without much
  spare height, `footerArea` could overtake and overlap `mainArea`
  once the keyboard showed. Fixed by centering `mainArea` within the
  space actually available between `statusArea` and `footerArea`.
- **Real visual bug in `NebulaPasswordField`** (found during the real
  authentication round-trip test): the typed-character dots could
  paint outside the field's rounded frame during internal
  auto-scrolling — missing `clip: true` on the internal `TextInput`.
  One-line fix, no public API impact.
- **`check-installation.sh`**'s module-load smoke test only inspected
  captured output text, never the actual exit code — a silently
  crashed load test (e.g. no display available) was indistinguishable
  from a clean success. Now checks the exit code explicitly.
- **`scripts/check-design-system.sh`**: `qmllint` isn't always on
  `PATH` — now locates it via `qmake6 -query QT_INSTALL_BINS` as a
  fallback, same pattern `install-nebula.sh` uses for `QT_INSTALL_QML`.
- **Deployment**: `install-nebula.sh` configures
  `GreeterEnvironment=QML_XHR_ALLOW_FILE_READ=1` in
  `/etc/sddm.conf.d/nebula.conf` — without it, `NebulaThemeLoader`
  silently fails to read `theme.conf` under the real `sddm.service` and
  every installed theme falls back to the Core's default colors with
  zero visible error (DT-0023 in `docs/Decisions-Techniques.md`).
- **`NebulaWallpaper`/`NebulaAvatar`** now `console.warn` when a
  theme-provided image path is explicitly set but fails to load — the
  "no source given" fallback (used by `template`) stays exactly as
  silent as before.
- **Documentation coherence**: `docs/Core-API.md`'s header used to
  claim "no implementation here — pre-implementation contract",
  directly contradicting `README.md`'s own §Status — fixed, along with three
  other comments that had described a pre-Loader/pre-adapter reality
  long after those things were actually built. `README.md` itself was
  restructured with explicit per-audience starting points (end user /
  theme developer / Core contributor) and a real theme gallery, and
  `docs/Login-Architecture.md` now documents why
  `NebulaPasswordField.username` is wired manually rather than
  resolved automatically.

### Known limitations

- **Icon tinting is not supported** (`iconColor`, considered during
  Core Refinement): tinting an arbitrary image without a shader isn't
  possible in plain QtQuick, and `ShaderEffect`/`MultiEffect` are
  explicitly forbidden in the Core. Icons must be provided pre-colored
  by the theme.
- **Button label contrast is not guaranteed**: `NebulaButton` always
  uses `theme.colors.textPrimary` for its label regardless of
  `variant`, with no dedicated "text on primary color" token. Measured
  real WCAG contrast: Nord's Unlock button fails at 1.74:1 (normal
  text needs 4.5:1); Glass sits at ~3.6:1 (passes only for large text).
  A future dedicated token is likely but not implemented this release.
- **No real translation infrastructure**: the labels made overridable
  this release are plain string properties with a fixed default, not a
  `qsTr()`/locale-file system. Sufficient for a theme to hardcode a
  different language, not for runtime language switching.
- **`NebulaThemeLoader` requires `XMLHttpRequest`**, which Qt6 disables
  for local files by default — `install-nebula.sh` now configures this
  automatically for a system install, but standalone testing
  (`qml6`/`sddm-greeter --test-mode` from the repo) still needs
  `QML_XHR_ALLOW_FILE_READ=1` set manually — see
  `docs/Development-Environment.md`.
- **SDDM is a hard prerequisite, not detected automatically**: Nebula
  themes an SDDM greeter specifically. Some current KDE distributions
  (e.g. KDE Linux) ship a different login manager (`plasmalogin`) by
  default and don't have SDDM installed at all — `install-nebula.sh`
  doesn't currently check for SDDM's presence before writing files
  under `/usr/share/sddm/`/`/etc/sddm.conf.d/`.
- **HiDPI/multi-monitor tested at the resolutions actually available**:
  validated at 100/125/150/200% scale factors across 3 real physical
  monitors (Phase 3.0/3.1) — not exhaustively tested across every
  possible resolution/monitor-count combination, only what the
  development and clean-test machines' hardware provided.
- **`qmllint` output isn't fully portable across Qt6 builds**: the same
  reported version (6.11.1) produced dramatically more
  `missing-property`/`unqualified-access` warnings on a different
  machine than on the primary development machine, for identical
  files. Not a real Core defect (confirmed: the affected components
  render and behave correctly on both machines) — `check-design-system.sh`
  already only fails on a non-zero `qmllint` exit code, never on
  warning count, so this doesn't block a real workflow, but expect the
  raw warning count to vary by system.
- **`NebulaKeyboardSelector`** is documented in `Core-API.md` but still
  not implemented — no theme uses it.
- **No animation has been moved into the Core**: only Glass uses any
  (fade+scale appear, pulse-on-select, shake-on-error), and its own two
  variants share one `Main.qml`, so reuse across genuinely independent
  themes isn't demonstrated yet.
- **Minor residual visual artifact in `NebulaPasswordField`**: the
  leftmost typed-character dot can appear half-cut depending on the
  internal `TextInput`'s auto-scroll position — an inherent artifact of
  that scrolling mechanism (also visible on other native password
  fields, e.g. macOS/GTK), not specific to Nebula. A full fix would need
  a dynamically adjusted clip padding for negligible visual gain — not
  pursued.
- **A handful of internal code-quality items were found and
  deliberately deferred**, each explicitly waiting on a second
  independent theme/consumer to demonstrate real need rather than
  guessed at now: a shared text-style helper for Core components, the
  `SDDMSessionAdapter`/`SDDMUserAdapter` list-materialization
  duplication, a defensive `.disconnect()` guard in
  `NebulaAuthService`. None affect current behavior — see
  [`docs/Architecture-Review-2026.md`](docs/Architecture-Review-2026.md)
  §9 for the full, argued list.

### Roadmap

See [`docs/Roadmap.md`](docs/Roadmap.md) Phase 3 for the live,
authoritative list. Next planned: `cyberpunk`, `hacker`, `amoled`,
`hypr` themes; `core/effects/` (`BlurEffect`, `GlowEffect`,
`Particles`) once a real theme demonstrates the need;
`NebulaWallpaperEngine`/`NebulaSoundManager`.
