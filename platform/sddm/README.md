# Platform / SDDM

Adapters binding Nebula's Core services to the real SDDM context
properties confirmed in [`docs/Prototype-Results.md`](../../docs/Prototype-Results.md)
§3.2 (`sddm`, `userModel`, `sessionModel`, `keyboard`).

Phase 3.2 status (see [`docs/Roadmap.md`](../../docs/Roadmap.md)):
`SDDMPowerAdapter` (3.2.1), `SDDMSessionAdapter` (3.2.2) and
`SDDMUserAdapter` (3.2.3) are real and fully verified under
`--test-mode`. `SDDMSessionAdapter`/`SDDMUserAdapter` materialize their
respective `sessionModel`/`userModel` via an `Instantiator` — always
access model roles as `model.<role>`, a bare identifier does not get
auto-populated in a `QtObject` delegate here, see
`docs/Development-Journal.md`, 2026-08-02 — Phase 3.2.
`SDDMAuthAdapter` (3.2.4) is coded and passively verified (clean
`qmllint`, clean load under `--test-mode`) but its real login
round-trip is **not yet validated** — `--test-mode` never connects a
real auth backend (`Prototype-Results.md` §3.5), so this needs a
supervised test under the real `sddm.service`, following the safe
protocol documented for the same-day VT/DRM incident. See
[`docs/Services-Architecture.md`](../../docs/Services-Architecture.md)
and [`docs/Core-Implementation-Status.md`](../../docs/Core-Implementation-Status.md).
