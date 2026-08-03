# Changelog — Nebula

Format inspired by [Keep a Changelog](https://keepachangelog.com/).
Versions before 0.1 Beta were internal development phases, not
releases — see [`docs/Roadmap.md`](docs/Roadmap.md) for that full
history rather than repeating it here.

## [Unreleased]

### Added

- **`NebulaVirtualKeyboard`** (`core/components/`, plus internal
  `NebulaInputPanel`): fixes VK-001, an on-screen keyboard rendered at a
  fixed, oversized size on mixed-DPI multi-monitor setups. Hosts a real
  `QtQuick.VirtualKeyboard.InputPanel` instead of letting Qt fall back to
  its own detached `DesktopInputPanel` — see
  [`docs/Investigations/VK-001-VirtualKeyboard.md`](docs/Investigations/VK-001-VirtualKeyboard.md)
  and [`docs/Core-API.md`](docs/Core-API.md). Shown only via an explicit
  toggle button, never automatically on focus. Wired into `template`,
  `glass-dark`, `glass-light`; `nord` is out of scope (no real password
  field). Validated under a real `sddm.service` across 3 physical
  monitors on all 3 themes it's wired into (`template`, `glass-dark`,
  `glass-light`), including the decisive `QT_SCALE_FACTOR=2`
  re-measurement on `template` (see the investigation doc's "Validation
  réelle" section).
- **`NebulaLoginLayout.bottomInset`**: additive property keeping the main
  content and footer visible above the virtual keyboard when shown.

### Fixed

- **Real race condition, found during VK-001's real-hardware
  validation**: `NebulaVirtualKeyboard.keyboardActive` depended on Qt's
  own async `InputMethod.visible` rather than the component's own
  synchronous `state`, so the keyboard panel could visually slide into
  view before `bottomInset` updated — intermittently leaving it
  overlapping the login form instead of making room for it. Fixed by
  deriving `keyboardActive` from `state` directly.
- **Real layout bug in `NebulaLoginLayout`, found the same session**:
  `mainArea` only ever compensated by half of `bottomInset` while
  `footerArea` compensated the full amount, relying on spare screen
  height to absorb the difference. On screens without much to spare
  (confirmed on a laptop panel and a 1920×1200 monitor, not reproduced
  on a 4K screen), once the keyboard showed, `footerArea` could overtake
  and overlap `mainArea`. Not keyboard-specific — would affect any theme
  whose footer grows large enough on a short screen. Fixed by centering
  `mainArea` within the space actually available between `statusArea`
  and `footerArea` instead of the whole screen.

## [0.1 Beta] — 2026-07-31

First public release. Milestone brief:
`Nebula — Milestone 0.1 Beta.md` — the question this milestone answers
is not "does Nebula work?" but "can someone outside the project use
it?", validated on a genuinely separate machine (fresh Arch Linux
container, zero prior Nebula history), not just the development
machine.

### Added

- **Core**, stable and documented: `NebulaThemeConfig`/
  `NebulaThemeProvider`/`NebulaThemeLoader`, `NebulaButton`,
  `NebulaAvatar`, `NebulaClock`, `NebulaDate`, `NebulaUserList`,
  `NebulaPasswordField`, `NebulaSessionSelector`, `NebulaPowerButtons`,
  `NebulaLoginLayout`, `NebulaBackground`/`NebulaWallpaper`/
  `NebulaOverlay`/`NebulaSurface`. Public API considered frozen as of
  this release — see
  [`docs/API-Stability-Review.md`](docs/API-Stability-Review.md).
- **Services/Platform abstraction**: `NebulaAuthService`/
  `NebulaUserService`/`NebulaSessionService`/`NebulaPowerService` +
  `platform/sddm/` adapters — Core components never call SDDM directly.
- **Icon support**: `icon`/`iconSize` on `NebulaButton`; `showIcon`/
  `hideIcon`/`iconSize` on `NebulaPasswordField`; `shutdownIcon`/
  `rebootIcon`/`suspendIcon`/`hibernateIcon`/`iconSize` on
  `NebulaPowerButtons`. All optional — no component requires an icon.
- **Localizable labels**: previously hardcoded strings ("Show"/"Hide",
  "Shut Down"/"Restart"/"Sleep"/"Hibernate"/"Confirm?") are now
  overridable properties with the same defaults.
- **Four official themes**: `template` (starter/reference), `nord`,
  `glass-dark`, `glass-light` (frosted-glass, light/dark variants
  sharing every token name). Each independently installable, no Core
  modification required.
- **Installation system**: `scripts/install-nebula.sh`/
  `uninstall-nebula.sh`/`check-installation.sh`/`check-theme.sh`/
  `check-design-system.sh` — idempotent, tested on a genuinely clean
  machine (fresh install, multi-theme coexistence, selective/full
  uninstall, bad-input handling, re-run idempotency).
- **Theme SDK**: `themes/template/` + `docs/Theme-SDK.md` (normative
  contract) + `docs/Creating-A-Theme.md` (tutorial) + `docs/Core-API.md`
  (component contracts) + `docs/Design-Tokens-Reference.md` (every
  token, with accurate real-usage data as of this release) — validated
  by actually building a theme from documentation alone, without
  consulting `core/` source (see `docs/Development-Journal.md`,
  Milestone 0.1 Beta entry).
- [`docs/Third-Party-Licenses.md`](docs/Third-Party-Licenses.md): every
  bundled asset (icons, wallpapers) is an original creation for this
  project (GPLv3); the only external dependency (Noto Sans, used by
  Glass) is a system font under SIL OFL 1.1, never bundled.

### Fixed

- **Real accessibility bug**: `KeyNavigation.tab` targeting
  `NebulaPasswordField` left keyboard focus on the outer `Rectangle`
  instead of the internal `TextInput` — present since the component's
  introduction, never noticed because the focus-border styling still
  looked correct. Fixed in the Core; every theme using this component
  benefits automatically.
- **Real bug in `check-installation.sh`**: its module-load smoke test
  only inspected captured output text, never the actual exit code — a
  silently crashed load test (e.g. no display available) was
  indistinguishable from a genuinely clean, silent success. Now checks
  the exit code explicitly.
- **`scripts/check-design-system.sh`**: `qmllint` isn't always on
  `PATH` (Arch's `qt6-declarative` package installs it under
  `/usr/lib/qt6/bin/`, not `/usr/bin`, unlike some other distributions)
  — the script now locates it via `qmake6 -query QT_INSTALL_BINS` as a
  fallback, matching the pattern `install-nebula.sh` already used for
  `QT_INSTALL_QML`.
- **Deployment**: `install-nebula.sh` now configures
  `GreeterEnvironment=QML_XHR_ALLOW_FILE_READ=1` in
  `/etc/sddm.conf.d/nebula.conf` — without it, `NebulaThemeLoader`
  silently fails to read `theme.conf` under the real `sddm.service` and
  every installed theme falls back to the Core's hardcoded default
  colors, with zero visible error (found during Glass's validation,
  fixed for all themes — see DT-0023 in
  `docs/Decisions-Techniques.md`).
- **Documentation**: `README.md` was severely stale (claimed "no theme
  exists yet" and "installation instructions will be added once a
  first theme ships" — both long since false). Rewritten to reflect
  actual current state; 11 existing docs that existed but were never
  linked from `README.md` are now discoverable;
  `docs/Design-Tokens-Reference.md`'s "used by" columns (stale since
  Phase 1.6) now reflect real, current component usage; `CLAUDE.md`'s
  status section (stale since Phase 1.5) now reflects the actual
  project state.

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

### Roadmap

See [`docs/Roadmap.md`](docs/Roadmap.md) Phase 3 for the live,
authoritative list. Next planned: `cyberpunk`, `hacker`, `amoled`,
`hypr` themes; `core/effects/` (`BlurEffect`, `GlowEffect`,
`Particles`) once a real theme demonstrates the need;
`NebulaWallpaperEngine`/`NebulaSoundManager`.
