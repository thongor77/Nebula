import QtQuick

// Public contract for system power actions — shutdown, reboot, suspend.
// Components depend on this, never on SDDM's `sddm.powerOff()` /
// `sddm.reboot()` / `sddm.suspend()` directly (see
// docs/Nebula-Principles.md §2/§6 — that prohibition is the whole point
// of this service). Delegates to a swappable `adapter` (duck-typed: must
// expose `canShutdown`/`canReboot`/`canSuspend` (bool) and
// `shutdown()`/`reboot()`/`suspend()`) — a mock adapter in tests, a real
// SDDMPowerAdapter later (see docs/Services-Architecture.md).
QtObject {
    id: root

    property var adapter: null

    readonly property bool canShutdown: adapter ? adapter.canShutdown : false
    readonly property bool canReboot: adapter ? adapter.canReboot : false
    readonly property bool canSuspend: adapter ? adapter.canSuspend : false

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
}
