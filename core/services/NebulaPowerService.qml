import QtQuick

// Public contract for system power actions — shutdown, reboot, suspend,
// hibernate. Components depend on this, never on SDDM's `sddm.powerOff()` /
// `sddm.reboot()` / `sddm.suspend()` / `sddm.hibernate()` directly (see
// docs/Nebula-Principles.md §2/§6 — that prohibition is the whole point
// of this service). Delegates to a swappable `adapter` (duck-typed: must
// expose `canShutdown`/`canReboot`/`canSuspend`/`canHibernate` (bool) and
// `shutdown()`/`reboot()`/`suspend()`/`hibernate()`) — a mock adapter in
// tests, a real SDDMPowerAdapter later (see docs/Services-Architecture.md).
//
// `canHibernate`/`hibernate()` added in Phase 2.3 for NebulaPowerButtons
// — already anticipated in docs/Core-API.md's NebulaPowerButtons entry
// (`sddm.canHibernate`/`sddm.hibernate()` confirmed real SDDM API, see
// docs/Prototype-Results.md §3.2), not a new capability invented here.
QtObject {
    id: root

    property var adapter: null

    readonly property bool canShutdown: adapter ? adapter.canShutdown : false
    readonly property bool canReboot: adapter ? adapter.canReboot : false
    readonly property bool canSuspend: adapter ? adapter.canSuspend : false
    readonly property bool canHibernate: adapter ? adapter.canHibernate : false

    function shutdown() {
        if (adapter && canShutdown) {
            adapter.shutdown()
        }
    }

    function reboot() {
        if (adapter && canReboot) {
            adapter.reboot()
        }
    }

    function suspend() {
        if (adapter && canSuspend) {
            adapter.suspend()
        }
    }

    function hibernate() {
        if (adapter && canHibernate) {
            adapter.hibernate()
        }
    }
}
