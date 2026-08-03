import QtQuick

// Real binding between NebulaPowerService and the SDDM `sddm` context
// property — confirmed real API, see docs/Prototype-Results.md §3.2 and
// docs/Development-Journal.md, 2026-08-02 — Phase 3.2 (Phase 3.2.1).
// Note the name mismatch: our own `canShutdown` maps to SDDM's
// `canPowerOff` / `powerOff()`, not `canShutdown`/`shutdown()` — SDDM has
// no such property, only `powerOff`.
//
// `sddm` only exists as a context property when this file is loaded by
// sddm-greeter (real service or --test-mode) — always true here, since
// platform/sddm/ adapters are only ever instantiated by a theme's
// Main.qml, itself only ever run through sddm-greeter, never standalone.
QtObject {
    readonly property bool canShutdown: sddm.canPowerOff
    readonly property bool canReboot: sddm.canReboot
    readonly property bool canSuspend: sddm.canSuspend
    readonly property bool canHibernate: sddm.canHibernate

    function shutdown() {
        sddm.powerOff()
    }

    function reboot() {
        sddm.reboot()
    }

    function suspend() {
        sddm.suspend()
    }

    function hibernate() {
        sddm.hibernate()
    }
}
