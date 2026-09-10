import QtQuick

// Fake auth backend for harnesses — proves NebulaAuthService works with
// zero SDDM dependency. Simulates a short async round-trip so the
// authenticating/succeeded/failed states are actually exercised, not
// just instantiated. Never touches anything real.
//
// Item, not QtObject: needs a child Timer, and QtObject has no default
// property to hold one (found by actually running this file — see
// docs/Development-Journal.md, Phase 1.4). Never shown on screen, so the
// visual baggage of Item is harmless here.
Item {
    id: root

    property bool nextResultSucceeds: true

    // Exercised by a harness's own assertions/console.log — the real
    // contract (NebulaAuthService.authenticate(),
    // SDDMAuthAdapter.login()) always passes sessionIndex as a 3rd
    // argument; this mock used to only declare 2 parameters, so JS
    // silently dropped it and no harness ever exercised that path
    // (Architecture-Review-2026.md §3/§9).
    property int lastSessionIndex: -1

    signal loginResult(bool success, string reason)

    function login(username, password, sessionIndex) {
        root.lastSessionIndex = sessionIndex
        resultTimer.restart()
    }

    function cancel() {
        resultTimer.stop()
    }

    Timer {
        id: resultTimer
        interval: 300
        onTriggered: root.loginResult(root.nextResultSucceeds,
            root.nextResultSucceeds ? "" : "Mock authentication failure")
    }
}
