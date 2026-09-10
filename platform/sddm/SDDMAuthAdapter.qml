import QtQuick

// Real binding between NebulaAuthService and the SDDM `sddm` context
// property — confirmed real API (`sddm.login(username, password,
// sessionIndex)`, `sddm.loginSucceeded()`/`loginFailed()`, both
// signals confirmed with **no arguments**), see docs/Prototype-Results.md
// §3.2 and docs/Development-Journal.md, 2026-08-02 — Phase 3.2
// (3.2.0/3.2.4).
//
// Real SDDM never gives the greeter a failure reason string — `reason`
// below is always a generic Nebula-chosen string, never something from
// SDDM (confirmed by reading the real `breeze` theme's own
// `onLoginFailed()`, which takes no argument).
//
// `sessionIndex` defaults to -1 when `NebulaAuthService.sessionService`
// isn't set (see DT-0024 in docs/Decisions-Techniques.md) — falls back
// to `sessionModel.lastIndex` in that case rather than failing the call.
//
// Not Nebula-prefixed: this lives in platform/, not core/ — it is a
// concrete, SDDM-specific binding, not a reusable Core abstraction (see
// docs/Decisions-Techniques.md, DT-0010).
//
// QtObject, not Item: no declarative child needed here (unlike
// SDDMUserAdapter/SDDMSessionAdapter's Instantiator) — connecting to
// `sddm`'s own signals imperatively in Component.onCompleted works
// directly on QtObject, same reasoning already used by
// NebulaAuthService for its own adapter connection (see
// docs/Development-Journal.md, Phase 1.4).
//
// Verified under the real sddm.service (not just --test-mode, which
// never connects a real authentication backend — see
// docs/Prototype-Results.md §3.5): the full login round-trip was
// exercised end-to-end on 2026-08-03, Phase 3.2 — see
// docs/Real-Adapter-Validation.md.
QtObject {
    id: root

    signal loginResult(bool success, string reason)

    Component.onCompleted: {
        sddm.loginSucceeded.connect(_handleLoginSucceeded)
        sddm.loginFailed.connect(_handleLoginFailed)
    }

    function login(username, password, sessionIndex) {
        var resolvedIndex = (sessionIndex !== undefined && sessionIndex >= 0)
            ? sessionIndex
            : sessionModel.lastIndex
        sddm.login(username, password, resolvedIndex)
    }

    function cancel() {
        // No real SDDM API to abort an in-flight sddm.login() call —
        // sddm.loginSucceeded()/loginFailed() are the only signals it
        // ever emits (see docs/Prototype-Results.md §3.2). Cancelling is
        // therefore purely a NebulaAuthService-side state reset
        // (`authenticating` back to false); nothing to call here — a
        // real, documented limitation, not an oversight.
    }

    function _handleLoginSucceeded() {
        root.loginResult(true, "")
    }

    function _handleLoginFailed() {
        root.loginResult(false, "Authentication failed")
    }
}
