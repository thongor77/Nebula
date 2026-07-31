import QtQuick

// Future contact point between NebulaPowerService and the real SDDM
// `sddm` context property (`sddm.canPowerOff`/`canReboot`/`canSuspend`/
// `canHibernate`, `sddm.powerOff()`/`reboot()`/`suspend()`/`hibernate()`
// — confirmed real API, see docs/Prototype-Results.md §3.2). Skeleton
// only: capabilities default to false and actions are no-ops, so nothing
// can accidentally trigger a real system action before this is wired for
// real — see docs/Services-Architecture.md.
QtObject {
    property bool canShutdown: false
    property bool canReboot: false
    property bool canSuspend: false
    property bool canHibernate: false

    function shutdown() {
        console.warn("SDDMPowerAdapter.shutdown: not implemented yet (Phase 1.4 skeleton)")
    }

    function reboot() {
        console.warn("SDDMPowerAdapter.reboot: not implemented yet (Phase 1.4 skeleton)")
    }

    function suspend() {
        console.warn("SDDMPowerAdapter.suspend: not implemented yet (Phase 1.4 skeleton)")
    }

    function hibernate() {
        console.warn("SDDMPowerAdapter.hibernate: not implemented yet (Phase 1.4 skeleton)")
    }
}
