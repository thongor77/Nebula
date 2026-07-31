import QtQuick

// Fake power backend for harnesses — proves NebulaPowerService works
// with zero SDDM dependency. Actions only log; never a real system call.
QtObject {
    property bool canShutdown: true
    property bool canReboot: true
    property bool canSuspend: true
    property bool canHibernate: true

    function shutdown() {
        console.log("MockPowerAdapter: shutdown() called (no-op, test harness)")
    }

    function reboot() {
        console.log("MockPowerAdapter: reboot() called (no-op, test harness)")
    }

    function suspend() {
        console.log("MockPowerAdapter: suspend() called (no-op, test harness)")
    }

    function hibernate() {
        console.log("MockPowerAdapter: hibernate() called (no-op, test harness)")
    }
}
