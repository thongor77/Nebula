# Dashboard (Experimental)

**Experimental — not an official theme yet.** A real daily-use experiment,
not a finished product: validating whether a left (context) / center
(authentication) / right (controls) triptych composition earns its
place over repeated real logins, built entirely on [`core/`](../../core/)
with no modification to it. See
[`../../docs/Dashboard-Theme-Report.md`](../../docs/Dashboard-Theme-Report.md)
for the full validation write-up and
[`../../docs/Dashboard-Usability-Log.md`](../../docs/Dashboard-Usability-Log.md)
for the ongoing daily-use log. Evolved from the architecture stress test
that first proved this composition possible without any Core change —
see [`../../docs/Dashboard-Architecture-Stress-Test.md`](../../docs/Dashboard-Architecture-Stress-Test.md).

![Hero](../../photos/dashboard/hero.png)

> **Screenshots below predate the Phase C grayscale redesign** (still
> show the earlier cosmic indigo/violet identity) and the network panel
> — pending a refresh, see the implementation report for details.

## Layout

| Region | Content |
|---|---|
| **Left — Context** | Clock, date, a small theme wordmark |
| **Center — Authentication** | Avatar/user selection, password, Unlock, error/busy status |
| **Right — Controls** | Ethernet/Wi-Fi status (wide only, experimental — see below), session selector, virtual-keyboard toggle, power actions |

`NebulaLoginLayout` is deliberately not used — its zones are hard-capped
to a single centered column by Core contract, unsuited to three
simultaneous regions. The root layout is hand-assembled from
`NebulaBackground` + `NebulaSurface` + the interactive components, every
one of them used exclusively through its documented public API (see
`Dashboard-Architecture-Stress-Test.md`, Gap 1).

Nothing here is mocked: unlike the earlier stress-test prototype (static
"Host/Battery/Network" placeholder text), every element on screen is
wired to a real Core Service. If a Service reports nothing available
(e.g. the real `SDDMPowerAdapter`'s skeleton `can*` flags, all `false`
under real SDDM today), the corresponding control simply doesn't render
— never a dead placeholder.

## Responsive behavior

Three width tiers, theme-local properties (`wideBreakpoint: 1200`,
`mediumBreakpoint: 900`), not `theme.conf` keys — see
`Dashboard-Architecture-Stress-Test.md` Gap 2:

- **Wide** (≥1200px): full triptych, side panels at the stage edges. The
  Network status card only ever appears at this tier — see "Experimental
  network status" below.
- **Medium** (900–1199px): the left context panel stays beside the card
  (it always fits); session/keyboard/power fold into one wrapping block
  below the card instead — real measurement showed
  `NebulaPowerButtons`' own un-wrappable 4-button row never fits beside
  the card at any medium width (see the Theme Report's Core-gap note).
- **Narrow** (<900px): the same fallback as medium, both panels folded
  above/below the centered auth card — controls stay reachable, per the
  brief's own small-screen strategy, rather than simply hidden.

![Detail](../../photos/dashboard/detail.png)
![Responsive](../../photos/dashboard/responsive.png)

## Identity

**Grayscale — clean, architectural, calm.** Replaced the original
cosmic indigo/violet identity (Phase C of
[`../../Nebula-Dashboard-Grayscale-Network-Implementation-Brief.md`](../../Nebula-Dashboard-Grayscale-Network-Implementation-Brief.md)):
charcoal background, graphite surfaces, off-white primary text, muted
secondary text, and a single restrained cool steel-blue accent reserved
for focus/selection — never used for network status (see below).
Personality comes from proportion/typography/spacing/hierarchy/surfaces,
not color. No GPU blur/shader (Core has none, see
`../../docs/Rendering-Guidelines.md`); depth comes from
`surfaceOpacity`/`overlayOpacity` plus the wallpaper alone, same approach
as Glass. `theme.conf` overrides the same 17 tokens as before (9 colors,
2 radii, 3 surface/overlay, 1 animation duration, 2 fonts — Noto Sans,
an existing system-font dependency, see
`../../docs/Third-Party-Licenses.md`), values changed only.

Contrast measured (sRGB relative-luminance): the Unlock button's label
is now ~11.4:1 on its primary-color background — passes WCAG AA for
both large and small text, well ahead of the previous ~3.38:1. A side
effect of going monochrome (a dark graphite `primaryColor` pairs
naturally with light text), not a deliberate contrast-fix task —
`NebulaButton` still always uses `textPrimary` regardless of `variant`,
the same known Core limitation as before, not introduced here (see
`../../docs/Core-Refinement-Review.md`).

## Experimental network status

The right panel's Ethernet/Wi-Fi card (wide layout only) reads
NetworkManager over the system D-Bus via
[`services/NetworkStatusModel.qml`](services/NetworkStatusModel.qml) and
renders through [`components/NetworkStatus.qml`](components/NetworkStatus.qml).
**This is Dashboard-local, not a Nebula Core API** — no
`NebulaNetworkService`, no `SDDMNetworkAdapter`, no `Nebula.Network`
import anywhere in `core/` or `platform/` (see
`Nebula-Dashboard-Grayscale-Network-Implementation-Brief.md` §3).

- **Dependency**: [`org.kde.plasma.workspace.dbus`](https://invent.kde.org/plasma/plasma-workspace),
  a QML D-Bus binding shipped by the `plasma-workspace` package — not
  part of Nebula's universal Qt6/SDDM-only dependency set, and not a
  documented/stable public API (an internal Plasma Workspace QML
  plugin). Never added as a Core/universal dependency; stays
  Dashboard-local and experimental for exactly that reason.
- **What it shows**: overall Ethernet/Wi-Fi presence and connected/
  offline state, the active interface name, and (best-effort only) the
  connected Wi-Fi SSID. Status display only — no IP/MAC/gateway/DNS, no
  scanning, no NetworkManager mutation, no controls.
- **Graceful degradation**: `NetworkStatusModel.qml` never statically
  imports the plugin (QML has no conditional import, and a failed
  top-level `import` would break the whole theme) — every D-Bus object
  is built at runtime via `Qt.createQmlObject()` inside `try`/`catch`.
  On a machine without `plasma-workspace`, or if the system bus is
  unreachable, the whole card just stays hidden; authentication is
  unaffected. Confirmed by running the real greeter with
  `plasma-workspace`'s plugin available — the "plugin missing" path is
  exercised by code review and the `try`/`catch` structure, not by an
  actual machine lacking the package (none was available to test
  against here).
- **Real-hardware validation**: read-only NetworkManager D-Bus access
  (property reads, not method calls — see the design note below) works
  for the unprivileged `sddm` user with no extra privileges, polkit
  rules, or policy changes. Verified with `sddm-greeter-qt6 --test-mode`
  across three real, mixed-DPI displays: device enumeration, per-device
  `DeviceType`/`State`/`Interface`, and SSID all read correctly and
  reactively, zero new QML warnings.
- **Design note**: the NetworkManager root object's own methods (e.g.
  `GetDevices()`) return `org.freedesktop.DBus.Error.AccessDenied` for
  an unprivileged caller — the default D-Bus policy only opens the
  `org.freedesktop.DBus.Properties` interface to non-root callers. This
  is not a bug: `NetworkStatusModel` never needed the method call in the
  first place, since NetworkManager's own `Devices` *property* already
  lists every device path, and per-device D-Bus *properties* provide
  everything else — the whole model is built on the properties path.

## Assets

- `assets/wallpapers/dashboard.jpg` (2189×1375) — the user's own desktop
  wallpaper, swapped in for the earlier procedural indigo/violet
  gradient (which was generated for this project, ImageMagick, no
  provenance question). **License unverified**: this file's origin
  (filename suggests a downloaded wallpaper, no EXIF provenance) is not
  confirmed to be redistributable under this repository's license
  (GPLv3) — resolve before this asset is pushed to the public remote.
- `assets/icons/`, `assets/fonts/` — empty: `NebulaAvatar`'s built-in
  zero-asset fallback silhouette covers the current scope, and Noto Sans
  is a system font, never bundled.

## Known limitations (this phase)

- Real `SDDMSessionAdapter`/`SDDMPowerAdapter`/`SDDMUserAdapter` are
  still Phase 1.4 skeletons under real SDDM (empty sessions, no power
  capability, empty user list beyond the logged-in account) — a
  pre-existing, already-documented limitation, not introduced by this
  theme. The right panel and its whole `NebulaSurface` correctly stay
  hidden when nothing is available, confirmed on real hardware.
- `NebulaKeyboardSelector` (real keyboard *layout* selection, as opposed
  to the on-screen virtual keyboard) is documented in `Core-API.md` but
  still never implemented — the right panel's "keyboard" control is only
  the virtual-keyboard show/hide toggle.
- `NebulaPowerButtons`' internal 4-button `Row` cannot wrap and has no
  compact/icon-only mode — at very narrow widths (roughly <600px, well
  below any realistic desktop/laptop display) all four buttons can still
  overflow the available width. A real, reusable Core gap — see the
  Theme Report for the smallest proposed fix. Not worked around further
  here (single-theme need, doesn't meet the API-freeze bar today).
- The network status card depends on `plasma-workspace` being installed
  (see "Experimental network status" above) — a machine without it
  simply won't show the card, never a broken login, but this is the
  first Dashboard-local code with a dependency beyond Qt6/SDDM. Not
  proposed for Core promotion yet (single-theme need — see
  `Nebula-Dashboard-Grayscale-Network-Implementation-Brief.md` §3).
- The "plugin missing" degradation path (see above) is validated by
  code structure (`try`/`catch` around every dynamic D-Bus object), not
  by an actual test machine without `plasma-workspace` — none was
  available during this validation pass.

## Options

`theme.conf` overrides 17 tokens (see Identity above). Panel visibility
and the two responsive breakpoints are plain QML properties in
`Main.qml`, not `theme.conf` keys — see
`Dashboard-Architecture-Stress-Test.md` Gap 2 for why.
